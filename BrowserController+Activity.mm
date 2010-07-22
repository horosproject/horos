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

#import "BrowserController+Activity.h"
#import "ThreadsManager.h"
#import "ThreadCell.h"
#import "MenuMeterCPUStats.h"
#import "MenuMeterNetStats.h"
#import <OsiriX Headers/NSImage+N2.h>
#import <OsiriX Headers/N2Operators.h>
#import <mach/mach_port.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/storage/IOBlockStorageDriver.h>
#import <algorithm>
#import "NSUserDefaultsController+OsiriX.h"

@interface ActivityObserver : NSObject {
	BrowserController* _bc;
}

-(id)initWithBrowserController:(BrowserController*)bc;

@end

@implementation BrowserController (Activity)

-(void)awakeActivity {
//	tableView = [BrowserController currentBrowser].AtableView;
//	cpuActiView = [BrowserController currentBrowser].AcpuActiView;
//	hddActiView = [BrowserController currentBrowser].AhddActiView;
//	netActiView = [BrowserController currentBrowser].AnetActiView;
//	statusLabel = [BrowserController currentBrowser].AstatusLabel;
	
	[AtableView setDelegate: self];
	
	_activityCells = [[NSMutableArray alloc] init];

//	_manager = [manager retain];
	// we observe the threads array so we can release cells when they're not needed anymore
	activityObserver = [[ActivityObserver alloc] initWithBrowserController:self];
	[[ThreadsManager defaultManager] addObserver:activityObserver forKeyPath:@"threads" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionInitial context:NULL];
	
	AupdateStatsThread = [[NSThread alloc] initWithTarget:self selector:@selector(updateStatsThread:) object:NULL];
	[AupdateStatsThread start];
	
	[[AtableView tableColumnWithIdentifier:@"all"] bind:@"value" toObject:[ThreadsManager defaultManager].threadsController withKeyPath:@"arrangedObjects" options:NULL];
	
//	[NSThread detachNewThreadSelector:@selector(testThread_creator:) toTarget:self withObject:NULL];
//	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(testTimer_createThread2:) userInfo:NULL repeats:YES];
}

/*-(void)testThread_creator:(id)t {
	[[ThreadsManager defaultManager] addThread:[NSThread currentThread]];
	[NSThread currentThread].name = @"CreatorZ joinZyX";
	[[NSThread currentThread] setSupportsCancel:YES];
	int c = 0;
	while (YES) { // ![[NSThread currentThread] isCancelled]
		c++;
		[NSThread detachNewThreadSelector:@selector(testThread_dummy:) toTarget:self withObject:NULL];
		[[NSThread currentThread] setStatus:[NSString stringWithFormat:@"So far, I jungled %d threads..", c]];
		[NSThread sleepForTimeInterval:CGFloat(random()%1000)/1000*2];
	}
}

-(void)testThread_dummy:(id)obj {
	[[ThreadsManager defaultManager] addThread:[NSThread currentThread]];
	[NSThread sleepForTimeInterval:0.001];
	[[ThreadsManager defaultManager] removeThread:[NSThread currentThread]];
}

-(void)testTimer_createThread2:(NSTimer*)t {
//	NSThread* th = [NSThread detachNewThreadSelector:@selector(testThread_dummy2:) toTarget:self withObject:NULL];
//	[[ThreadsManager defaultManager] addThread:th];
}

-(void)testThread_dummy2:(id)obj {
	//
}*/


-(void)deallocActivity {
	[AupdateStatsThread cancel];
	[AupdateStatsThread release];
	
	[[ThreadsManager defaultManager] removeObserver:activityObserver forKeyPath:@"threads"];
	[activityObserver release];
	
	[_activityCells release];
	
    [super dealloc];
}

-(NSCell*)cellForThread:(NSThread*)thread {
	for (ThreadCell* cell in _activityCells)
		if (cell.thread == thread)
			return cell;
	
	return nil;
}

-(NSCell*) createCellForThread:(NSThread*)thread {
	NSCell* cell = [[ThreadCell alloc] initWithThread:thread manager:[ThreadsManager defaultManager] view:AtableView];
	[_activityCells addObject:cell];
	
	return [cell autorelease];
}

const CGFloat greenHue = 1./3, redHue = 0, deltaHue = redHue-greenHue;

+(NSImage*)cpuActivityImage:(NSImage*)image meanLoad:(CGFloat)meanload maxLoad:(CGFloat)maxload {
	NSImage* meanimage = [image imageWithHue:deltaHue*meanload];
	NSImage* maximage = [image imageWithHue:deltaHue*maxload];
	NSSize size = maximage.size;
	
	[meanimage lockFocus];
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	NSBezierPath* clipPath = [NSBezierPath bezierPath];
	[clipPath moveToPoint:NSZeroPoint];
	[clipPath lineToPoint:NSMakePoint(size.width, 0)];
	[clipPath lineToPoint:NSMakePoint(size.width, size.height)];
	[clipPath closePath];
	[clipPath setClip];
	
	[maximage drawAtPoint:NSZeroPoint fromRect:NSMakeRect(NSZeroPoint, size) operation:NSCompositeCopy fraction:1];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	[meanimage unlockFocus];
	return meanimage;
}

-(void)updateStatsThread:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
//	MenuMeterCPUStats* menuMeterCPUStats = [[MenuMeterCPUStats alloc] init];
//	MenuMeterNetStats* menuMeterNetStats = [[MenuMeterNetStats alloc] init];
	
	#define historyLen 100
//	CGFloat cpuCurrLoad = -1, netCurrLoad = -1, hddCurrLoad = -1;
//	NSUInteger prevTotalRW = 0;
//	CGFloat hddTimedDeltaRWs[historyLen];
//	memset(hddTimedDeltaRWs, 0, sizeof(hddTimedDeltaRWs));
//	NSTimeInterval previousTime = [NSDate timeIntervalSinceReferenceDate];
	
//	mach_port_t masterPort;
//	IOMasterPort(MACH_PORT_NULL, &masterPort);
	
//	NSImage* cpuImage = [NSImage imageNamed:@"activity_cpu.png"];
//	NSImage* netImage = [NSImage imageNamed:@"activity_net.png"];
//	NSImage* hddImage = [NSImage imageNamed:@"activity_hdd.png"];
	
	while (![[NSThread currentThread] isCancelled]) {
		[NSThread sleepForTimeInterval:0.5];

		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		//NSTimeInterval thisTime = [NSDate timeIntervalSinceReferenceDate], thisInterval = thisTime - previousTime;
		/*
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
			CGFloat load = meanload+maxload*10;//(meanload+maxload)/2;
			if (fabs(cpuCurrLoad-load) > 0.01)
			{
				[AcpuActiView setImage:[BrowserController cpuActivityImage:cpuImage meanLoad:meanload maxLoad:maxload]];
				[AcpuActiView performSelectorOnMainThread:@selector(setNeedsDisplay:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
				cpuCurrLoad = load;
			}
		} else
			[AcpuActiView setImage:NULL]; // TO DO maybe: grayed image
		
		// NET
		
		NSDictionary* netLoads = [menuMeterNetStats netStatsForInterval:1];
		if (netLoads) {
			CGFloat totpeak = 0, totdeltain = 0;
			for (NSString* key in netLoads) {
				totpeak += [[[netLoads objectForKey:key] objectForKey:@"peak"] floatValue];
				totdeltain += [[[netLoads objectForKey:key] objectForKey:@"deltain"] floatValue];;
			} CGFloat load = totdeltain/totpeak;
			if (fabs(netCurrLoad-load) > 0.01)
			{
				[AnetActiView setImage:[netImage imageWithHue: deltaHue*load]];
				[AnetActiView performSelectorOnMainThread:@selector(setNeedsDisplay:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
				netCurrLoad = load;
			}
		} else
			[AnetActiView setImage:NULL]; // TO DO maybe: grayed image
		
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
				
				if (fabs(hddCurrLoad-load) > 0.01)
				{
					[AhddActiView setImage:[hddImage imageWithHue: deltaHue*load]];
					[AhddActiView performSelectorOnMainThread:@selector(setNeedsDisplay:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
					hddCurrLoad = load;
				}
			}
			
			prevTotalRW = totalRW;			
		} else [AhddActiView setImage:NULL];
		*/
		int threadCount = [ThreadsManager defaultManager].threads.count;
		NSString *activityString = @"";
		if (threadCount>0)
		{
			activityString = [NSString stringWithFormat:NSLocalizedString(threadCount==1?@"%d thread":@"%d threads", NULL), threadCount];
		}
		[AstatusLabel performSelectorOnMainThread:@selector(setStringValue:) withObject:activityString waitUntilDone:YES];
		
		//previousTime = thisTime;
		[pool release];
	}
	
//	[menuMeterNetStats release];
//	[menuMeterCPUStats release];
	[pool release];
}

-(void)activity_observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	if (obj == [ThreadsManager defaultManager])
		if ([keyPath isEqual:@"threads"]) { // we observe the threads array so we can release cells when they're not needed anymore
			if ([[change objectForKey:NSKeyValueChangeKindKey] unsignedIntValue] == NSKeyValueChangeRemoval)
				for (NSThread* thread in [change objectForKey:NSKeyValueChangeOldKey])
				{
					id cell = [self cellForThread:thread];
					if( cell)
						[_activityCells removeObject: cell];
				}
			return;
		}
	
}

-(NSCell*)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
	if (tableView == AtableView)
		@try {
			id cell = [self cellForThread: [[ThreadsManager defaultManager] threadAtIndex:row]];
		
			if( cell == nil)
				cell = [self createCellForThread: [[ThreadsManager defaultManager] threadAtIndex:row]];
		
			return cell;
		} @catch (...) {
		}
	
	return NULL;
}

@end


@implementation ThreadsTableView

-(void)selectRowIndexes:(NSIndexSet*)indexes byExtendingSelection:(BOOL)extend {
}

-(void)mouseDown:(NSEvent*)evt {
}

-(void)rightMouseDown:(NSEvent*)evt {
}

@end

@implementation ActivityObserver

-(id)initWithBrowserController:(BrowserController*)bc {
	self = [super init];
	_bc = bc; // no retaining here
	return self;
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	[_bc activity_observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end