//
//  CHSinglyLinkedList.h
//  CHDataStructures
//
//  Copyright © 2008-2021, Quinn Taylor
//  Copyright © 2002, Phillip Morelock
//

#import <CHDataStructures/CHLinkedList.h>

NS_ASSUME_NONNULL_BEGIN

/**
 @file CHSinglyLinkedList.h
 A standard singly-linked list implementation with pointers to head and tail.
 */

/** A struct for nodes in a CHSinglyLinkedList. */
typedef struct CHSinglyLinkedListNode {
	__unsafe_unretained id object; ///< The object associated with this node in the list.
	struct CHSinglyLinkedListNode *_Nullable next; ///< The next node in the list.
} CHSinglyLinkedListNode;

#pragma mark -

/**
 A standard singly-linked list implementation with pointers to head and tail. This is ideally suited for use in LIFO and FIFO structures (stacks and queues). The lack of backwards links precludes backwards enumeration, and removing from the tail of the list is O(n), rather than O(1). However, other operations are slightly faster than for doubly-linked lists. Nodes are represented with C structs, providing much faster performance than Objective-C objects.
 
 This implementation uses a dummy head node, which simplifies both insertion and deletion by eliminating the need to check whether the first node in the list must change. We opt not to use a dummy tail node since the lack of a previous pointer makes starting at the end of the list rather pointless. The pointer to the tail (either the dummy head node or the last "real" node in the list) is only used for inserting at the end without traversing the entire list first. The figures below demonstrate what a singly-linked list looks like when it contains 0 objects, 1 object, and 2 or more objects.
 
 @image html singly-linked-0.png Figure 1 - Singly-linked list with 0 objects.
 
 @image html singly-linked-1.png Figure 2 - Singly-linked list with 1 object.
 
 @image html singly-linked-N.png Figure 3 - Singly-linked list with 2+ objects.
 
 To reduce code duplication, all methods that append or prepend objects to the list call \link #insertObject:atIndex:\endlink, and the methods to remove the first or last objects use \link #removeObjectAtIndex:\endlink underneath.
 
 Singly-linked lists are well-suited as an underlying collection for other data structures, such as stacks and queues (see CHListStack and CHListQueue). The same functionality can be achieved using a circular buffer and an array, and many libraries choose to do so when objects are only added to or removed from the ends, but the dynamic structure of a linked list is much more flexible when inserting and deleting in the middle of a list.
 
 The primary weakness of singly-linked lists is the absence of a previous link. Since insertion and deletion involve changing the @c next link of the preceding node, and there is no way to step backwards through the list, traversal must always begin at the head, even if searching for an index that is very close to the tail. This does not mean that singly-linked lists are inherently bad, only that they are not well-suited for all possible applications. As usual, all data access attributes should be considered before choosing a data strcuture.
 */
@interface CHSinglyLinkedList<__covariant ObjectType> : NSObject <CHLinkedList>
{
	CHSinglyLinkedListNode *head; // Dummy node at the front of the list.
	CHSinglyLinkedListNode *tail; // Pointer to last node in a list.
	CHSinglyLinkedListNode *cachedNode; // Pointer to last accessed node.
	NSUInteger cachedIndex; // Index of last accessed node.
	NSUInteger count; // The number of objects currently stored in a list.
	unsigned long mutations; // Tracks mutations for NSFastEnumeration.
}

- (instancetype)initWithArray:(NSArray<ObjectType> *)array NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
