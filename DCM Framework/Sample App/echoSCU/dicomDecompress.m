#import <Foundation/Foundation.h>
#import <Osirix/DCM.h>


int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    // insert code here...
    
	if (argc <= 2) {
		NSLog(@"sourceFiles destinationFile");
	}
	else{		
		NSString *source = [NSString stringWithUTF8String:argv[1]];
		NSString *dest = [NSString stringWithUTF8String:argv[2]];
		DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:source decodingPixelData:NO];
		[dcmObject writeToFile:dest withTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] quality:100 atomically:YES];
	}
    [pool release];
    return 0;
}



