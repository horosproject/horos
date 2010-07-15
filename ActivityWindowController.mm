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

#import "ActivityWindowController.h"
#import "ThreadsManager.h"
#import "ThreadCell.h"
#import "MenuMeterCPUStats.h"
#import "MenuMeterNetStats.h"
#import <OsiriX Headers/NSImage+N2.h>
#import <mach/mach_port.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/storage/IOBlockStorageDriver.h>
#import <algorithm>
#import "NSUserDefaultsController+OsiriX.h"
#import "BrowserController.h"

@implementation ActivityWindowController

@synthesize manager = _manager;
@synthesize tableView;
@synthesize cpuActiView, hddActiView, netActiView;
@synthesize statusLabel;

+(ActivityWindowController*)defaultController {
	static ActivityWindowController* defaultController = [[self alloc] initWithManager:[ThreadsManager defaultManager]];
	return defaultController;
}

-(id)initWithManager:(ThreadsManager*)manager {
    self = [super init];
	
	tableView = [BrowserController currentBrowser].AtableView;
	cpuActiView = [BrowserController currentBrowser].AcpuActiView;
	hddActiView = [BrowserController currentBrowser].AhddActiView;
	netActiView = [BrowserController currentBrowser].AnetActiView;
	statusLabel = [BrowserController currentBrowser].AstatusLabel;
	
	[tableView setDelegate: self];
	
	_cells = [[NSMutableArray alloc] init];

	_manager = [manager retain];
	// we observe the threads array so we can release cells when they're not needed anymore
	[self.manager addObserver:self forKeyPath:@"threads" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionInitial context:NULL];
	
	updateStatsThread = [[NSThread alloc] initWithTarget:self selector:@selector(updateStatsThread:) object:NULL];
	[updateStatsThread start];
	
	[[self.tableView tableColumnWithIdentifier:@"all"] bind:@"value" toObject:self.manager.threadsController withKeyPath:@"arrangedObjects" options:NULL];
	
    return self;
}

-(void)dealloc {
	[updateStatsThread cancel];
	[updateStatsThread release];
	
	[self.manager removeObserver:self forKeyPath:@"threads"];
	
    [_manager release];
	[_cells release];
    [super dealloc];
}

-(NSString*)windowFrameAutosaveName {
	return [NSString stringWithFormat:@"ActivityWindow frame: %@", [[self window] title]];
}

-(NSCell*)cellForThread:(NSThread*)thread {
	for (ThreadCell* cell in _cells)
		if (cell.thread == thread)
			return cell;
	
	return nil;
}

-(NSCell*) createCellForThread:(NSThread*)thread {
	NSCell* cell = [[ThreadCell alloc] initWithThread:thread manager:self.manager view:self.tableView];
	[_cells addObject:cell];
	
	return [cell autorelease];
}

-(void)updateStatsThread:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	MenuMeterCPUStats* menuMeterCPUStats = [[MenuMeterCPUStats alloc] init];
	MenuMeterNetStats* menuMeterNetStats = [[MenuMeterNetStats alloc] init];
	
	const CGFloat greenHue = 1./3, redHue = 0, deltaHue = redHue-greenHue;
	
	#define historyLen 100
	CGFloat cpuCurrLoad = -1, netCurrLoad = -1, hddCurrLoad = -1;
	NSUInteger prevTotalRW = 0;
	CGFloat hddTimedDeltaRWs[historyLen];
	memset(hddTimedDeltaRWs, 0, sizeof(hddTimedDeltaRWs));
	NSTimeInterval previousTime = [NSDate timeIntervalSinceReferenceDate];
	
	mach_port_t masterPort;
	IOMasterPort(MACH_PORT_NULL, &masterPort);
	
	
	while (![[NSThread currentThread] isCancelled]) {
		[NSThread sleepForTimeInterval:0.1];

		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		NSTimeInterval thisTime = [NSDate timeIntervalSinceReferenceDate], thisInterval = thisTime - previousTime;
		
		// CPU
		
		NSArray* cpuLoads = [menuMeterCPUStats currentLoad];
		if (cpuLoads) {
			CGFloat meanload = 0, maxload = 0;
			for (NSDictionary* cpuLoad in cpuLoads) {
				CGFloat thisLoad = 0;
				for (NSString* key in cpuLoad)
					thisLoad += [[cpuLoad objectForKey:key] floatValue]/cpuLoad.count;
				meanload += thisLoad/cpuLoads.count;
				maxload = std::max(maxload, thisLoad);
			}
			CGFloat load = maxload;//(meanload+maxload)/2;
			if (fabs(cpuCurrLoad-load) > 0.01) {
				[cpuActiView setImage:[cpuActiView.image imageWithHue:greenHue+deltaHue*load]];
				[cpuActiView performSelectorOnMainThread:@selector(setNeedsDisplay:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
				cpuCurrLoad = load;
			}
		} else
			[cpuActiView setImage:NULL]; // TODO: grayed image
		
		// NET
		
		NSDictionary* netLoads = [menuMeterNetStats netStatsForInterval:1];
		if (netLoads) {
			CGFloat totpeak = 0, totdeltain = 0;
			for (NSString* key in netLoads) {
				totpeak += [[[netLoads objectForKey:key] objectForKey:@"peak"] floatValue];
				totdeltain += [[[netLoads objectForKey:key] objectForKey:@"deltain"] floatValue];;
			} CGFloat load = totdeltain/totpeak;
			if (fabs(netCurrLoad-load) > 0.01) {
				[netActiView setImage:[netActiView.image imageWithHue:greenHue+deltaHue*load]];
				[netActiView performSelectorOnMainThread:@selector(setNeedsDisplay:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
				netCurrLoad = load;
			}
		} else
			[netActiView setImage:NULL]; // TODO: grayed image
		
		// HDD
		
		NSUInteger totalRW = 0;
		io_iterator_t blockDeviceIterator;
		if (IOServiceGetMatchingServices(masterPort, IOServiceMatching(kIOBlockStorageDriverClass), &blockDeviceIterator) == KERN_SUCCESS) {
			io_registry_entry_t driveEntry = MACH_PORT_NULL;
			while ((driveEntry = IOIteratorNext(blockDeviceIterator))) {
				CFDictionaryRef statistics = (CFDictionaryRef)IORegistryEntryCreateCFProperty(driveEntry, CFSTR(kIOBlockStorageDriverStatisticsKey), kCFAllocatorDefault, kNilOptions);
				if (statistics) {
					NSNumber* statNumber = (NSNumber*)[(NSDictionary*)statistics objectForKey:(NSString*)CFSTR(kIOBlockStorageDriverStatisticsBytesReadKey)];
					if (statNumber)
						totalRW += [statNumber unsignedLongLongValue];
					statNumber = (NSNumber*)[(NSDictionary*)statistics objectForKey:(NSString*)CFSTR(kIOBlockStorageDriverStatisticsBytesWrittenKey)];
					if (statNumber)
						totalRW += [statNumber unsignedLongLongValue];
					CFRelease(statistics);
				}
			}
			IOObjectRelease(blockDeviceIterator);
		}
		if (totalRW) {
			if (prevTotalRW) {
				memcpy(&hddTimedDeltaRWs[0], &hddTimedDeltaRWs[1], sizeof(CGFloat)*(historyLen-1));
				NSUInteger thisDeltaRW = totalRW-prevTotalRW;
				hddTimedDeltaRWs[historyLen-1] = 1.*thisDeltaRW/thisInterval;
				
				CGFloat maxTimedDeltaRW = 0;
				for (size_t i = 0; i < historyLen; ++i)
					maxTimedDeltaRW = std::max(maxTimedDeltaRW, hddTimedDeltaRWs[i]);
				
				CGFloat load = hddTimedDeltaRWs[historyLen-1]/maxTimedDeltaRW;
				
				if (fabs(hddCurrLoad-load) > 0.01) {
					[hddActiView setImage:[hddActiView.image imageWithHue:greenHue+deltaHue*load]];
					[hddActiView performSelectorOnMainThread:@selector(setNeedsDisplay:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
					hddCurrLoad = load;
				}
			}
			
			prevTotalRW = totalRW;			
		} else [hddActiView setImage:NULL];
		
		[statusLabel performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:NSLocalizedString(self.manager.threads.count==1?@"%d background thread is running":@"%d background threads are running", NULL), self.manager.threads.count] waitUntilDone:YES];
		
		previousTime = thisTime;
		[pool release];
	}
	
	[menuMeterNetStats release];
	[menuMeterCPUStats release];
	[pool release];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	if (obj == self.manager)
		if ([keyPath isEqual:@"threads"]) { // we observe the threads array so we can release cells when they're not needed anymore
			if ([[change objectForKey:NSKeyValueChangeKindKey] unsignedIntValue] == NSKeyValueChangeRemoval)
				for (NSThread* thread in [change objectForKey:NSKeyValueChangeOldKey])
				{
					id cell = [self cellForThread:thread];
					if( cell)
						[_cells removeObject: cell];
				}
			return;
		}
	
	[super observeValueForKeyPath:keyPath ofObject:obj change:change context:context];
}

-(NSCell*)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
	id cell = [self cellForThread: [self.manager threadAtIndex:row]];
	
	if( cell == nil)
		cell = [self createCellForThread: [self.manager threadAtIndex:row]];
	
	return cell;
}

@end


@implementation ThreadsTableView

-(void)selectRowIndexes:(NSIndexSet*)indexes byExtendingSelection:(BOOL)extend {
}

-(void)mouseDown:(NSEvent*)evt {
}

@end
