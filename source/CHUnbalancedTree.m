//
//  CHUnbalancedTree.m
//  CHDataStructures
//
//  Copyright © 2008-2021, Quinn Taylor
//  Copyright © 2002, Phillip Morelock
//

#import <CHDataStructures/CHUnbalancedTree.h>
#import "CHAbstractBinarySearchTree_Internal.h"

@implementation CHUnbalancedTree

- (void)addObject:(id)anObject {
	CHRaiseInvalidArgumentExceptionIfNil(anObject);
	++mutations;
	
	CHBinaryTreeNode *parent = header, *current = header->right;
	sentinel->object = anObject; // Assure that we find a spot to insert
	NSComparisonResult comparison;
	while ((comparison = [current->object compare:anObject])) {
		parent = current;
		current = current->link[comparison == NSOrderedAscending]; // R on YES
	}
	
	[anObject retain]; // Must retain whether replacing value or adding new node
	if (current != sentinel) {
		// Replace the existing object with the new object.
		[current->object release];
		current->object = anObject;		
	} else {
		// Create a new node to hold the value being inserted
		current = [self _createNodeWithObject:anObject];
		++count;
		// Link from parent as the proper child, based on last comparison
		comparison = [parent->object compare:anObject]; // restore prior compare
		parent->link[comparison == NSOrderedAscending] = current;
	}
}


// Removal is guaranteed to not make the tree deeper/taller, since it uses the
// "min of the right subtree" algorithm if the node to be removed has 2 children.
- (void)removeObject:(id)anObject {
	CHRaiseInvalidArgumentExceptionIfNil(anObject);
	if (count == 0) {
		return;
	}
	++mutations;
	
	CHBinaryTreeNode *parent = nil, *current = header;
	
	sentinel->object = anObject; // Assure that we find a spot to insert
	NSComparisonResult comparison;
	while ((comparison = [current->object compare:anObject])) {
		parent = current;
		current = current->link[comparison == NSOrderedAscending]; // R on YES
	}
	NSAssert(parent != nil, @"Illegal state, parent should never be nil!");
	// Exit if the specified node was not found in the tree.
	if (current == sentinel) {
		return;
	}
	[current->object release]; // Object must be released in any case
	--count;
	if (current->left == sentinel || current->right == sentinel) {
		// One or both of the child pointers are null, so removal is simpler
		parent->link[parent->right == current]
			= current->link[current->left == sentinel];
		free(current);
	} else {
		// The most complex case: removing a node with 2 non-null children
		// (Replace object with the leftmost object in the right subtree.)
		parent = current;
		CHBinaryTreeNode *replacement = current->right;
		while (replacement->left != sentinel) {
			parent = replacement;
			replacement = replacement->left;
		}
		current->object = replacement->object;
		parent->link[parent->right == replacement] = replacement->right;
		free(replacement);
	}
}

@end
