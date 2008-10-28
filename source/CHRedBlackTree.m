/*
 CHRedBlackTree.m
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

#import "CHRedBlackTree.h"

static NSUInteger kCHRedBlackTreeNode = sizeof(CHRedBlackTreeNode);

#pragma mark Enumeration Struct & Macros

// A struct for use by CHUnbalancedTreeEnumerator to maintain traversal state.
typedef struct RBTE_NODE {
	struct CHRedBlackTreeNode *node;
	struct RBTE_NODE *next;
} RBTE_NODE;

static NSUInteger kRBTE_SIZE = sizeof(RBTE_NODE);

#pragma mark - Stack Operations

#define RBTE_PUSH(o) {tmp=malloc(kRBTE_SIZE);tmp->node=o;tmp->next=stack;stack=tmp;}
#define RBTE_POP()   {if(stack!=NULL){tmp=stack;stack=stack->next;free(tmp);}}
#define RBTE_TOP     ((stack!=NULL)?stack->node:NULL)

#pragma mark - Queue Operations

#define RBTE_ENQUEUE(o) {tmp=malloc(kRBTE_SIZE);tmp->node=o;tmp->next=NULL;\
if(queue==NULL){queue=tmp;queueTail=tmp;}\
queueTail->next=tmp;queueTail=queueTail->next;}
#define RBTE_DEQUEUE()  {if(queue!=NULL){tmp=queue;queue=queue->next;free(tmp);}\
if(queue==tmp)queue=NULL;if(queueTail==tmp)queueTail=NULL;}
#define RBTE_FRONT      ((queue!=NULL)?queue->node:NULL)

#pragma mark -

/**
 An NSEnumerator for traversing a CHRedBlackTree in a specified order.
 
 NOTE: Tree enumerators are tricky to do without recursion.
 Consider using a stack to store path so far?
 */
@interface CHRedBlackTreeEnumerator : NSEnumerator
{
	CHTraversalOrder traversalOrder;
	@private
	CHRedBlackTree *collection;
	struct RBNode *currentNode;
	BOOL hasStarted;
	BOOL beenLeft;
	BOOL beenRight;
	unsigned long mutationCount;
	unsigned long *mutationPtr;
}

/**
 Create an enumerator which traverses a given (sub)tree in the specified order.
 
 @param tree The tree collection that is being enumerated. This collection is to be
             retained while the enumerator has not exhausted all its objects.
 @param root The root node of the (sub)tree whose elements are to be enumerated.
 @param order The traversal order to use for enumerating the given (sub)tree.
 @param mutations A pointer to the collection's count of mutations, for invalidation.
 */
- (id) initWithTree:(CHRedBlackTree*)tree
               root:(CHRedBlackTreeNode*)root
     traversalOrder:(CHTraversalOrder)order
    mutationPointer:(unsigned long*)mutations;

/**
 Returns an array of objects the receiver has yet to enumerate.
 
 @return An array of objects the receiver has yet to enumerate.
 
 Invoking this method exhausts the remainder of the objects, such that subsequent
 invocations of #nextObject return <code>nil</code>.
 */
- (NSArray*) allObjects;

/**
 Returns the next object from the collection being enumerated.
 
 @return The next object from the collection being enumerated, or <code>nil</code>
 when all objects have been enumerated.
 */
- (id) nextObject;

@end

#pragma mark -

@implementation CHRedBlackTreeEnumerator

- (id) initWithTree:(CHRedBlackTree*)tree
               root:(CHRedBlackTreeNode*)root
     traversalOrder:(CHTraversalOrder)order
    mutationPointer:(unsigned long*)mutations
{
	if ([super init] == nil || !isValidTraversalOrder(order)) return nil;
	collection = (root != NULL) ? collection = [tree retain] : nil;
//	currentNode = ___;
	traversalOrder = order;
	beenLeft = YES;
	beenRight = NO;
	hasStarted = NO;
	mutationCount = *mutations;
	mutationPtr = mutations;
	return self;
}

- (void) dealloc {
	[collection release];
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

/**
 @see UnbalancedTreeEnumerator#nextObject
 */
- (id) nextObject {
	if (mutationCount != *mutationPtr)
		CHMutatedCollectionException([self class], _cmd);
	// TODO: Copy enumeration logic from UnbalancedTree
	return nil;
}

@end

#pragma mark -

#pragma mark C Functions for Optimized Operations

CHRedBlackTreeNode * _rotateNodeWithLeftChild(CHRedBlackTreeNode *node) {
	CHRedBlackTreeNode *leftChild = node->left;
	node->left = leftChild->right;
	leftChild->right = node;
	return leftChild;
}

CHRedBlackTreeNode * _rotateNodeWithRightChild(CHRedBlackTreeNode *node) {
	CHRedBlackTreeNode *rightChild = node->right;
	node->right = rightChild->left;
	rightChild->left = node;
	return rightChild;
}

CHRedBlackTreeNode* _rotateObjectOnAncestor(id x, CHRedBlackTreeNode *ancestor) {
	if ([x compare:ancestor->object] < 0) {
		ancestor->left = ([x compare:ancestor->left->object] < 0)
			? _rotateNodeWithLeftChild(ancestor->left)
			: _rotateNodeWithRightChild(ancestor->left);
		return ancestor->left;
	}
	else {
		ancestor->right = ([x compare:ancestor->right->object] < 0)
			? _rotateNodeWithLeftChild(ancestor->right)
			: _rotateNodeWithRightChild(ancestor->right);
		return ancestor->right;
	}
}

#pragma mark -

@implementation CHRedBlackTree

#pragma mark - Private Methods

- (void) _reorient:(id)x {
	current->color = kRED;
	current->left->color = kBLACK;
	current->right->color = kBLACK;
	if (parent->color == kRED) 	{
		grandparent->color = kRED;
		if ([x compare:grandparent->object] != [x compare:parent->object])
			parent = _rotateObjectOnAncestor(x, grandparent);
		current = _rotateObjectOnAncestor(x, greatgrandparent);
		current->color = kBLACK;
	}
	root->color = kBLACK;  // Always reset root to black
}

#pragma mark - Public Methods

- (id) init {
	if ([super init] == nil) return nil;
	sentinel = malloc(kCHRedBlackTreeNode);
	sentinel->object = nil;
	sentinel->color = kBLACK;
	sentinel->right = sentinel;
	sentinel->left = sentinel;
	root = sentinel;
	return self;
}

- (void) dealloc {
	[self removeAllObjects];
	free(sentinel);
	[super dealloc];
}

- (void) addObject:(id)anObject {
	if (anObject == nil)
		CHNilArgumentException([self class], _cmd);

	/*
	 Basically, as you walk down the tree to insert, if the present node has two
	 red children, you color it red and change the two children to black. If its
	 parent is red, the tree must be rotated. (Just change the root's color back
	 to black if you changed it). Returns without incrementing the count if the
	 object already exists in the tree.
	 */

	current = parent = grandparent = root;
	sentinel->object = anObject;
	
	NSComparisonResult comparison;
	while (comparison = [anObject compare:current->object]) {
		greatgrandparent = grandparent;
		grandparent = parent;
		parent = current;
		current = (comparison < 0) ? current->left : current->right;
		
		// Check for the bad case of red parent and red sibling of parent
		if (current->left->color == kRED && current->right->color == kRED)
			[self _reorient:anObject];
	}
	
	// If we didn't end up at a sentinel, replace the existing value and return.
	if (current != sentinel) {
		[anObject retain];
		[current->object release];
		current->object = anObject;
		return;
	}
	
	++count;
	current = malloc(kCHRedBlackTreeNode);
	current->object = [anObject retain];
	current->left = sentinel;
	current->right = sentinel;
	
	if (root == sentinel) {
		root = current;
		return;
	}
	
	if ([anObject compare:parent->object] < 0)
		parent->left = current;
	else
		parent->right = current;
	// one last reorientation check...
	[self _reorient:anObject];
}

- (BOOL) containsObject:(id)anObject {
	current = root;
	NSComparisonResult comparison;
	while (current != sentinel) {
		comparison = [current->object compare:anObject];
		if (comparison == NSOrderedDescending)
			current = current->left;
		else if (comparison == NSOrderedAscending)
			current = current->right;
		else
			return YES;
	}
	return NO;
}

- (id) findMax {
	sentinel->object = nil;
	current = root;
	while (current->right != sentinel)
		current = current->right;
	return current->object;
}

- (id) findMin {
	sentinel->object = nil;
	current = root;
	while (current->left != sentinel)
		current = current->left;
	return current->object;
}

- (id) findObject:(id)target {
	sentinel->object = target; // Set it so the target value is always "found".
	current = root;
	NSComparisonResult comparison;
	while (1) {
		comparison = [current->object compare:target];
		if (comparison == NSOrderedDescending)
			current = current->left;
		else if (comparison == NSOrderedAscending)
			current = current->right;
		else if (current != sentinel)
			return current->object;
		else
			return nil;
	}
}

/**
 @param anObject The object to be removed from the tree if present.
 
 @todo Implement <code>-removeObject:</code> method, including rebalancing.
 */
- (void) removeObject:(id)anObject {
	CHUnsupportedOperationException([self class], _cmd);
	// TODO: Next release, very difficult, my fu is no match for it right this minute.
}

- (void) removeAllObjects {
	CHRedBlackTreeNode *currentNode;
	RBTE_NODE *queue	 = NULL;
	RBTE_NODE *queueTail = NULL;
	RBTE_NODE *tmp;
	
	RBTE_ENQUEUE(root);
	while (1) {
		currentNode = RBTE_FRONT;
		if (currentNode == NULL)
			break;
		RBTE_DEQUEUE();
		if (currentNode->left != sentinel)
			RBTE_ENQUEUE(currentNode->left);
		if (currentNode->right != sentinel)
			RBTE_ENQUEUE(currentNode->right);
		[currentNode->object release];
		free(currentNode);
	}
	root = sentinel;
	count = 0;
	++mutations;
}

- (NSEnumerator*) objectEnumeratorWithTraversalOrder:(CHTraversalOrder)order {
	return [[[CHRedBlackTreeEnumerator alloc] initWithTree:self
                                                      root:root
                                            traversalOrder:order
                                           mutationPointer:&mutations] autorelease];
}

@end
