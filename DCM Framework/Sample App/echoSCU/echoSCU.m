#import <Foundation/Foundation.h>
#import <Osirix/DCM.h>

@class DCMVerificationSOPClassSCU;
int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    // insert code here...
    NSLog(@"Hello, World argc:%d", argc);
	if (argc <= 1) {
		NSLog(@"calledAET hostname port");
	}
	else{
		NSMutableDictionary *params = [NSMutableDictionary dictionary];
		[params setObject:[NSNumber numberWithInt:1] forKey:@"debugLevel"];
		[params setObject:@"ECHOSCU" forKey:@"callingAET"];
		[params setObject:[NSString stringWithUTF8String:argv[1]] forKey:@"calledAET"];
		[params setObject:[NSString stringWithUTF8String:argv[2]]  forKey:@"hostname"];
		[params setObject:[NSString stringWithUTF8String:argv[3]]  forKey:@"port"];
		BOOL status = [DCMVerificationSOPClassSCU echoSCUWithParams:params];
		 if (status)
			NSLog(@"Echo success");
		else
			NSLog(@"Echo failed");
		}
    [pool release];
    return 0;
}
