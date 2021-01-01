/*
 CHDataStructures.framework -- CHCircularBuffer.h
 
 Copyright (c) 2009-2010, Quinn Taylor <http://homepage.mac.com/quinntaylor>
 */

#import <CHDataStructures/CHUtil.h>

/**
 @file CHCircularBuffer.h
 
 A circular buffer array.
 */

/**
 A <a href="http://en.wikipedia.org/wiki/Circular_buffer">circular buffer</a> is a structure that emulates a continuous ring of N data slots. This class uses a C array and tracks the indexes of the front and back elements in the buffer, such that the first element is treated as logical index 0 regardless of where it is actually stored. The buffer dynamically expands to accommodate added objects. This type of storage is ideal for scenarios where objects are added and removed only at one or both ends (such as a stack or queue) but still supports all normal NSMutableArray functionality.
 
 @note Any method inherited from NSArray or NSMutableArray is supported by this class and its children. Please see the documentation for those classes for details.
*/
@interface CHCircularBuffer : NSMutableArray {
	__strong id *array; // Primitive C array for storing collection contents.
	NSUInteger arrayCapacity; // How many pointers @a array can accommodate.
	NSUInteger count; // The number of objects currently in the buffer.
	NSUInteger headIndex; // The array index of the first object.
	NSUInteger tailIndex; // The array index after the last object.
	unsigned long mutations; // Tracks mutations for NSFastEnumeration.
}

- (instancetype)initWithCapacity:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;

// The following methods are undocumented since they are only reimplementations.
// Users should consult the API documentation for NSArray and NSMutableArray.

- (instancetype)initWithArray:(NSArray *)anArray;

- (NSArray *)allObjects;
- (BOOL)containsObject:(id)anObject;
- (BOOL)containsObjectIdenticalTo:(id)anObject;
- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2;
- (id)firstObject;
- (NSUInteger)indexOfObject:(id)anObject;
- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject;
- (id)lastObject;
- (NSEnumerator *)objectEnumerator;
- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes;
- (void)removeAllObjects;
- (void)removeFirstObject;
- (void)removeLastObject;
- (void)removeObject:(id)anObject;
- (void)removeObjectIdenticalTo:(id)anObject;
- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
- (NSEnumerator *)reverseObjectEnumerator;

#pragma mark Adopted Protocols

- (void)encodeWithCoder:(NSCoder *)encoder;
- (instancetype)initWithCoder:(NSCoder *)decoder;
- (instancetype)copyWithZone:(NSZone *)zone;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id *)stackbuf
									count:(NSUInteger)len;

@end
