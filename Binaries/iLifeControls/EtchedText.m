#import "EtchedText.h"
#import "EtchedTextCell.h"

@implementation EtchedText

+ (Class)cellClass
{
	return [EtchedTextCell class];
}

- initWithCoder: (NSCoder *)origCoder
{
	if(![origCoder isKindOfClass: [NSKeyedUnarchiver class]]){
		self = [super initWithCoder: origCoder]; 
	} else {
		NSKeyedUnarchiver *coder = (id)origCoder;
		
		NSString *oldClassName = [[[self superclass] cellClass] className];
		Class oldClass = [coder classForClassName: oldClassName];
		if(!oldClass)
			oldClass = [[super superclass] cellClass];
		[coder setClass: [[self class] cellClass] forClassName: oldClassName];
		self = [super initWithCoder: coder];
		[coder setClass: oldClass forClassName: oldClassName];
		
		[self setShadowColor:[NSColor whiteColor]];
	}
	
	return self;
}

-(void)setShadowColor:(NSColor *)color
{
	EtchedTextCell *cell = [self cell];
	[cell setShadowColor:color];
}

@end
