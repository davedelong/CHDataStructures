/*
 CHDataStructures.framework -- CHUtil.m
 
 Copyright (c) 2008-2010, Quinn Taylor <http://homepage.mac.com/quinntaylor>
 */

#import <CHDataStructures/CHUtil.h>

size_t kCHPointerSize = sizeof(void *);

BOOL objectsAreEqual(id o1, id o2) {
	return [o1 isEqual:o2];
}

BOOL objectsAreIdentical(id o1, id o2) {
	return (o1 == o2);
}

BOOL collectionsAreEqual(id collection1, id collection2) {
	if ((collection1 && ![collection1 respondsToSelector:@selector(count)]) ||
		(collection2 && ![collection2 respondsToSelector:@selector(count)]))
	{
		[NSException raise:NSInvalidArgumentException
		            format:@"Parameter does not respond to -count selector."];
	}
	if (collection1 == collection2)
		return YES;
	if ([collection1 count] != [collection2 count])
		return NO;
	NSEnumerator *otherObjects = [collection2 objectEnumerator];
	for (id anObject in collection1) {
		if (![anObject isEqual:[otherObjects nextObject]])
			return NO;
	}
	return YES;	
}

NSUInteger hashOfCountAndObjects(NSUInteger count, id object1, id object2) {
	NSUInteger hash = 17 * count ^ (count << 16);
	return hash ^ (31*[object1 hash]) ^ ((31*[object2 hash]) << 4);
}

#pragma mark -

void CHIndexOutOfRangeException(Class aClass, SEL method,
                                NSUInteger index, NSUInteger count) {
	[NSException raise:NSRangeException
	            format:@"[%@ %s] -- Index (%lu) beyond bounds for count (%lu)",
	                   aClass, sel_getName(method), index, count];
}

void CHInvalidArgumentException(Class aClass, SEL method, NSString *string) {
	[NSException raise:NSInvalidArgumentException
	            format:@"[%@ %s] -- %@",
	                   aClass, sel_getName(method), string];
}

void CHNilArgumentException(Class aClass, SEL method) {
	CHInvalidArgumentException(aClass, method, @"Invalid nil argument");
}

void CHMutatedCollectionException(Class aClass, SEL method) {
	[NSException raise:NSGenericException
	            format:@"[%@ %s] -- Collection was mutated during enumeration",
	                   aClass, sel_getName(method)];
}

void CHUnsupportedOperationException(Class aClass, SEL method) {
	[NSException raise:NSInternalInconsistencyException
	            format:@"[%@ %s] -- Unsupported operation",
	                   aClass, sel_getName(method)];
}

void CHQuietLog(NSString *format, ...) {
	if (format == nil) {
		printf("(null)\n");
		return;
	}
	// Get a reference to the arguments that follow the format parameter
	va_list argList;
	va_start(argList, format);
	// Do format string argument substitution, reinstate %% escapes, then print
	NSMutableString *string = [[NSMutableString alloc] initWithFormat:format
	                                                        arguments:argList];
	va_end(argList);
	NSRange range;
	range.location = 0;
	range.length = [string length];
	[string replaceOccurrencesOfString:@"%%" withString:@"%%%%" options:0 range:range];
	printf("%s\n", [string UTF8String]);
	[string release];
}
