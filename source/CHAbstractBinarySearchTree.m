/*
 CHAbstractBinarySearchTree.m
 CHDataStructures.framework -- Objective-C versions of common data structures.
 Copyright (C) 2008, Quinn Taylor for BYU CocoaHeads <http://cocoaheads.byu.edu>
 Copyright (C) 2002, Phillip Morelock <http://www.phillipmorelock.com>
 
 This library is free software: you can redistribute it and/or modify it under
 the terms of the GNU Lesser General Public License as published by the Free
 Software Foundation, either under version 3 of the License, or (at your option)
 any later version.
 
 This library is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this library.  If not, see <http://www.gnu.org/copyleft/lesser.html>.
 */

#import "CHAbstractBinarySearchTree.h"
#import "CHAbstractBinarySearchTree_Internal.h"

// Definitions of variables declared as 'extern' in CHAbstractBinarySearchTree.h
size_t kCHBinaryTreeNodeSize = sizeof(CHBinaryTreeNode);
size_t kCHPointerSize = sizeof(void*);
BOOL kCHGarbageCollectionDisabled;

/**
 A dummy object that resides in the header node for a tree. Using a header node
 can simplify insertion logic by eliminating the need to check whether the root
 is null. In such cases, the tree root is generally stored as the right child of
 the header. In order to always proceed to the right child when traversing down
 the tree, instances of this class always return <code>NSOrderedAscending</code>
 when called as the receiver of the <code>-compare:</code> method.
 */
@interface CHSearchTreeHeaderObject : NSObject

/**
 Returns the singleton instance of this class. The singleton variable is defined
 in this file (CHAbstractBinarySearchTree.m) and is initialized only once in
 +[CHAbstractBinarySearchTree initialize].
 
 @return The singleton instance of this class.
 */
+ (id) headerObject;

/**
 Always indicate that the other object should appear to the right side. @b Note:
 To work correctly, this object @b must be the receiver of the -compare: message.
 
 @param otherObject The object to be compared to the receiver.
 @return <code>NSOrderedAscending</code>, indicating that traversal should go to
 the right child of the containing tree node.
 */
- (NSComparisonResult) compare:(id)otherObject;

@end

static CHSearchTreeHeaderObject *headerObject = nil;

@implementation CHSearchTreeHeaderObject

+ (id) headerObject {
	if (headerObject == nil)
		headerObject = [[CHSearchTreeHeaderObject alloc] init];
	return headerObject;
}

- (NSComparisonResult) compare:(id)otherObject {
	return NSOrderedAscending;
}

@end

#pragma mark -

@implementation CHAbstractBinarySearchTree

+ (void) initialize {
	kCHGarbageCollectionDisabled = !objc_collectingEnabled();
}

- (void) dealloc {
	[self removeAllObjects];
	free(header);
	free(sentinel);
	[super dealloc];
}

/**
 Only to be called from concrete child classes to initialize shared variables.
 */
- (id) init {
	if ([super init] == nil) return nil;
	count = 0;
	mutations = 0;
	
	// Allocate with no options, since it should never root its object reference
	sentinel = NSAllocateCollectable(kCHBinaryTreeNodeSize, 0);
	sentinel->object = nil;
	sentinel->right = sentinel;
	sentinel->left = sentinel;
	
	// Allocate with NSScannedOption so garbage collector scans object reference
	header = NSAllocateCollectable(kCHBinaryTreeNodeSize, NSScannedOption);
	header->object = [CHSearchTreeHeaderObject headerObject];
	header->right = sentinel;
	header->left = sentinel;
	return self;
}

- (id) initWithArray:(NSArray*)anArray {
	// Allow concrete child class to have a chance to initialize its own state.
	// (The -init method in any subclass must always call -[super init] first.)
	if ([self init] == nil) return nil;
	for (id anObject in anArray)
		[self addObject:anObject];
	return self;
}

#pragma mark <NSCoding>

- (id) initWithCoder:(NSCoder*)decoder {
	// Decode the array of objects and use it to initialize the tree's contents.
	return [self initWithArray:[decoder decodeObjectForKey:@"objects"]];
}

- (void) encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeObject:[self allObjectsWithTraversalOrder:CHTraverseLevelOrder]
	               forKey:@"objects"];
}

#pragma mark <NSCopying> methods

- (id) copyWithZone:(NSZone*)zone {
	id<CHSearchTree> newTree = [[[self class] alloc] init];
	for (id anObject in [self allObjectsWithTraversalOrder:CHTraverseLevelOrder])
		[newTree addObject:anObject];
	return newTree;
}

#pragma mark <NSFastEnumeration>

- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState*)state
                                   objects:(id*)stackbuf
                                     count:(NSUInteger)len
{
	CHBinaryTreeNode *current;
	CHBinaryTreeStack_DECLARE();
	
	// For the first call, start at leftmost node, otherwise the last saved node
	if (state->state == 0) {
		state->itemsPtr = stackbuf;
		state->mutationsPtr = &mutations;
		current = header->right;
		CHBinaryTreeStack_INIT();
	}
	else if (state->state == 1) {
		return 0;		
	}
	else {
		current = (CHBinaryTreeNode*) state->state;
		stack = (CHBinaryTreeNode**) state->extra[0];
		stackCapacity = (NSUInteger) state->extra[1];
		stackSize = (NSUInteger) state->extra[2];
	}
	NSAssert(current != nil, @"Illegal state, current should never be nil!");
	
	// Accumulate objects from the tree until we reach all nodes or the maximum
	NSUInteger batchCount = 0;
	while ( (current != sentinel || stackSize > 0) && batchCount < len) {
		while (current != sentinel) {
			CHBinaryTreeStack_PUSH(current);
			current = current->left;
		}
		current = CHBinaryTreeStack_POP(); // Save top node for return value
		NSAssert(current != nil, @"Illegal state, current should never be nil!");
		stackbuf[batchCount] = current->object;
		current = current->right;
		batchCount++;
	}
	
	if (current == sentinel && stackSize == 0) {
		CHBinaryTreeStack_FREE(stack);
		state->state = 1; // used as a termination flag
	}
	else {
		state->state    = (unsigned long) current;
		state->extra[0] = (unsigned long) stack;
		state->extra[1] = (unsigned long) stackCapacity;
		state->extra[2] = (unsigned long) stackSize;
	}
	return batchCount;
}

#pragma mark Concrete Implementations

- (NSArray*) allObjects {
	return [self allObjectsWithTraversalOrder:CHTraverseAscending];
}

- (NSArray*) allObjectsWithTraversalOrder:(CHTraversalOrder)order {
	return [[self objectEnumeratorWithTraversalOrder:order] allObjects];
}

- (BOOL) containsObject:(id)anObject {
	return ([self findObject:anObject] != nil);
}

- (NSUInteger) count {
	return count;
}

- (NSString*) description {
	return [[self allObjectsWithTraversalOrder:CHTraverseAscending] description];
}

- (id) findMax {
	sentinel->object = nil;
	CHBinaryTreeNode *current = header->right;
	while (current->right != sentinel)
		current = current->right;
	return current->object;
}

- (id) findMin {
	sentinel->object = nil;
	CHBinaryTreeNode *current = header->right;
	while (current->left != sentinel)
		current = current->left;
	return current->object;
}

- (id) findObject:(id)anObject {
	if (anObject == nil)
		return nil;
	sentinel->object = anObject; // Make sure the target value is always "found"
	CHBinaryTreeNode *current = header->right;
	NSComparisonResult comparison;
	while (comparison = [current->object compare:anObject]) // while not equal
		current = current->link[comparison == NSOrderedAscending]; // R on YES
	return (current != sentinel) ? current->object : nil;
}

/**
 Removes all nodes in the tree and releases the objects they point to. The root
 node's object pointer is reset to the sentinel, and the element count is reset
 to zero. If garbage collection is NOT enabled, the tree nodes are freed using a
 pre-order traversal by pushing child nodes on a stack. (This approach generally
 requires less space than level-order traversal, since it is depth-first instead
 of breadth-first, and should be faster, too.) Under garbage collection, setting
 the root node link to the sentinel will cause the entire graph of tree nodes to
 become eligible for garbage collection.
 */
- (void) removeAllObjects {
	if (count == 0)
		return;
	++mutations;
	
	CHBinaryTreeStack_DECLARE();
	CHBinaryTreeStack_INIT();
	CHBinaryTreeStack_PUSH(header->right);
	header->right = sentinel;

	if (kCHGarbageCollectionDisabled) {
		// Only bother with free() calls if garbage collection is NOT enabled.
		CHBinaryTreeNode *current;
		while (current = CHBinaryTreeStack_POP()) {
			if (current->right != sentinel)
				CHBinaryTreeStack_PUSH(current->right);
			if (current->left != sentinel)
				CHBinaryTreeStack_PUSH(current->left);
			[current->object release];
			free(current);
		}
		free(stack); // declared in CHBinaryTreeStack_DECLARE() macro
	}
	count = 0;
}

- (NSEnumerator*) objectEnumerator {
	return [self objectEnumeratorWithTraversalOrder:CHTraverseAscending];
}

- (NSEnumerator*) objectEnumeratorWithTraversalOrder:(CHTraversalOrder)order {
	return [[[CHBinarySearchTreeEnumerator alloc]
			 initWithTree:self
	                 root:header->right
	             sentinel:sentinel
	       traversalOrder:order
	      mutationPointer:&mutations] autorelease];
}

- (NSEnumerator*) reverseObjectEnumerator {
	return [self objectEnumeratorWithTraversalOrder:CHTraverseDescending];
}

- (NSString*) debugDescription {
	NSMutableString *description = [NSMutableString stringWithFormat:
	                                @"<%@: 0x%x> = {\n", [self class], self];
	CHBinaryTreeNode *current;
	CHBinaryTreeStack_DECLARE();
	CHBinaryTreeStack_INIT();
	
	sentinel->object = nil;
	if (header->right != sentinel)
		CHBinaryTreeStack_PUSH(header->right);	
	while (current = CHBinaryTreeStack_POP()) {
		if (current->right != sentinel)
			CHBinaryTreeStack_PUSH(current->right);
		if (current->left != sentinel)
			CHBinaryTreeStack_PUSH(current->left);
		// Append entry for the current node, including children
		[description appendFormat:@"\t%@ -> \"%@\" and \"%@\"\n",
		 [self debugDescriptionForNode:current],
		 current->left->object, current->right->object];
	}
	CHBinaryTreeStack_FREE(stack);
	[description appendString:@"}"];
	return description;
}

- (NSString*) debugDescriptionForNode:(CHBinaryTreeNode*)node {
	return [NSString stringWithFormat:@"\"%@\"", node->object];
}

- (NSString*) dotGraphString {
	NSMutableString *graph = [NSMutableString stringWithFormat:
							  @"digraph %@\n{\n", [self className]];
	if (header->right == sentinel) {
		[graph appendFormat:@"  nil;\n"];
	} else {
		NSString *leftChild, *rightChild;
		NSUInteger sentinelCount = 0;
		sentinel->object = nil;
		
		CHBinaryTreeNode *current;
		CHBinaryTreeStack_DECLARE();
		CHBinaryTreeStack_INIT();
		CHBinaryTreeStack_PUSH(header->right);
		// Uses a reverse pre-order traversal to make the DOT output look right.
		while (current = CHBinaryTreeStack_POP()) {
			if (current->left != sentinel)
				CHBinaryTreeStack_PUSH(current->left);
			if (current->right != sentinel)
				CHBinaryTreeStack_PUSH(current->right);
			// Append entry for node with any subclass-specific customizations.
			[graph appendString:[self dotStringForNode:current]];
			// Append entry for edges from current node to both its children.
			leftChild = (current->left->object == nil)
				? [NSString stringWithFormat:@"nil%d", ++sentinelCount]
				: [NSString stringWithFormat:@"\"%@\"", current->left->object];
			rightChild = (current->right->object == nil)
				? [NSString stringWithFormat:@"nil%d", ++sentinelCount]
				: [NSString stringWithFormat:@"\"%@\"", current->right->object];
			[graph appendFormat:@"  \"%@\" -> {%@;%@};\n",
			                    current->object, leftChild, rightChild];
		}
		CHBinaryTreeStack_FREE(stack);
		
		// Create entry for each null leaf node (each nil is modeled separately)
		for (int i = 1; i <= sentinelCount; i++)
			[graph appendFormat:@"  nil%d [shape=point,fillcolor=black];\n", i];
	}
	// Terminate the graph string, then return it
	[graph appendString:@"}\n"];
	return graph;
}

- (NSString*) dotStringForNode:(CHBinaryTreeNode*)node {
	return [NSString stringWithFormat:@"  \"%@\";\n", node->object];
}

#pragma mark Unsupported Implementations

- (void) addObject:(id)anObject {
	CHUnsupportedOperationException([self class], _cmd);
}

- (void) removeObject:(id)element {
	CHUnsupportedOperationException([self class], _cmd);
}

@end


#pragma mark -

@implementation CHBinarySearchTreeEnumerator

- (id) initWithTree:(id<CHSearchTree>)tree
               root:(CHBinaryTreeNode*)root
           sentinel:(CHBinaryTreeNode*)sentinel
     traversalOrder:(CHTraversalOrder)order
    mutationPointer:(unsigned long*)mutations
{
	if ([super init] == nil || !isValidTraversalOrder(order)) return nil;
	traversalOrder = order;
	collection = (root != sentinel) ? [tree retain] : nil;
	if (traversalOrder == CHTraverseLevelOrder) {
		CHBinaryTreeQueue_INIT();
		CHBinaryTreeQueue_ENQUEUE(root);
	} else {
		CHBinaryTreeStack_INIT();
		if (traversalOrder == CHTraversePreOrder) {
			CHBinaryTreeStack_PUSH(root);
		} else {
			current = root;
		}
	}
	sentinel->object = nil;
	sentinelNode = sentinel;
	mutationCount = *mutations;
	mutationPtr = mutations;
	return self;
}

- (void) dealloc {
	[collection release];
	free(stack);
	free(queue);
	[super dealloc];
}

- (NSArray*) allObjects {
	if (mutationCount != *mutationPtr)
		CHMutatedCollectionException([self class], _cmd);
	NSMutableArray *array = [[NSMutableArray alloc] init];
	id object;
	while ((object = [self nextObject]))
		[array addObject:object];
	[collection release];
	collection = nil;
	return [array autorelease];
}

- (id) nextObject {
	if (mutationCount != *mutationPtr)
		CHMutatedCollectionException([self class], _cmd);
	
	switch (traversalOrder) {
		case CHTraverseAscending: {
			if (stackSize == 0 && current == sentinelNode) {
				goto collectionExhausted;
			}
			while (current != sentinelNode) {
				CHBinaryTreeStack_PUSH(current);
				current = current->left;
				// TODO: How to not push/pop leaf nodes unnecessarily?
			}
			current = CHBinaryTreeStack_POP(); // Save top node for return value
			NSAssert(current != nil, @"Illegal state, current should never be nil!");
			id tempObject = current->object;
			current = current->right;
			return tempObject;
		}
			
		case CHTraverseDescending: {
			if (stackSize == 0 && current == sentinelNode) {
				goto collectionExhausted;
			}
			while (current != sentinelNode) {
				CHBinaryTreeStack_PUSH(current);
				current = current->right;
				// TODO: How to not push/pop leaf nodes unnecessarily?
			}
			current = CHBinaryTreeStack_POP(); // Save top node for return value
			NSAssert(current != nil, @"Illegal state, current should never be nil!");
			id tempObject = current->object;
			current = current->left;
			return tempObject;
		}
			
		case CHTraversePreOrder: {
			current = CHBinaryTreeStack_POP();
			if (current == NULL) {
				goto collectionExhausted;
			}
			if (current->right != sentinelNode)
				CHBinaryTreeStack_PUSH(current->right);
			if (current->left != sentinelNode)
				CHBinaryTreeStack_PUSH(current->left);
			return current->object;
		}
			
		case CHTraversePostOrder: {
			// This algorithm from: http://www.johny.ca/blog/archives/05/03/04/
			if (stackSize == 0 && current == sentinelNode) {
				goto collectionExhausted;
			}
			while (1) {
				while (current != sentinelNode) {
					CHBinaryTreeStack_PUSH(current);
					current = current->left;
				}
				NSAssert(stackSize > 0, @"Stack should never be empty!");
				// A null entry indicates that we've traversed the left subtree
				if (CHBinaryTreeStack_TOP != NULL) {
					current = CHBinaryTreeStack_TOP->right;
					CHBinaryTreeStack_PUSH(NULL);
					// TODO: How to not push a null pad for leaf nodes?
				}
				else {
					CHBinaryTreeStack_POP(); // ignore the null pad
					return CHBinaryTreeStack_POP()->object;
				}				
			}
		}
			
		case CHTraverseLevelOrder: {
			current = CHBinaryTreeQueue_FRONT;
			CHBinaryTreeQueue_DEQUEUE();
			if (current == NULL) {
				goto collectionExhausted;
			}
			if (current->left != sentinelNode)
				CHBinaryTreeQueue_ENQUEUE(current->left);
			if (current->right != sentinelNode)
				CHBinaryTreeQueue_ENQUEUE(current->right);
			return current->object;
		}
			
		collectionExhausted:
			[collection release];
			collection = nil;
			CHBinaryTreeStack_FREE(stack);
			CHBinaryTreeQueue_FREE(queue);
	}
	return nil;
}

@end