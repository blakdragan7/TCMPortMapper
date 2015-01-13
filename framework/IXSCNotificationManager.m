/*
 * Written by Theo Hultberg (theo@iconara.net) 2004-03-09 with help from Boaz Stuller.
 * This code is in the public domain, provided that this notice remains.
 * Fixes and additions in Nov 2008 by Dominik Wagner
 */

#import "IXSCNotificationManager.h"


/*!
 * @function       _IXSCNotificationCallback
 * @abstract       Callback for the dynamic store, just calls keysChanged: on 
 *                 the notification center.
 */
void _IXSCNotificationCallback( SCDynamicStoreRef store, CFArrayRef changedKeys, void *info ) {	
	NSEnumerator *keysE = [(__bridge NSArray *)changedKeys objectEnumerator];
	NSString *key = nil;
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	while ( key = [keysE nextObject] ) {		
		[nc postNotificationName:key 
							object:(__bridge id)info
						  userInfo:(__bridge NSDictionary *)SCDynamicStoreCopyValue(store, (__bridge CFStringRef) key)];
	}
}


@implementation IXSCNotificationManager

- (void)setObservedKeys:(NSArray *)inKeyArray regExes:(NSArray *)inRegExeArray {
	BOOL success = SCDynamicStoreSetNotificationKeys(
		dynStore, 
		(__bridge CFArrayRef)inKeyArray,
		(__bridge CFArrayRef)inRegExeArray
	);
	if (!success) NSLog(@"%s desired keys could not be observed.",__FUNCTION__);
}


- (id)init {
	self = [super init];
	if ( self ) {
		SCDynamicStoreContext context = { 0, (__bridge void *)self, NULL, NULL, NULL };
		
		dynStore = SCDynamicStoreCreate(
			NULL, 
			(__bridge CFStringRef) [[NSBundle mainBundle] bundleIdentifier],
			_IXSCNotificationCallback,
			&context
		);
		
		rlSrc = SCDynamicStoreCreateRunLoopSource(NULL,dynStore,0);
		CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], rlSrc, kCFRunLoopCommonModes);
		
		[self setObservedKeys:nil regExes:[NSArray arrayWithObject:@".*"]];
	}
	
	return self;
}

- (void)dealloc {
	CFRunLoopRemoveSource([[NSRunLoop currentRunLoop] getCFRunLoop], rlSrc, kCFRunLoopCommonModes);
	CFRelease(rlSrc);
	CFRelease(dynStore);
}

@end
