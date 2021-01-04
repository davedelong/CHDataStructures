//
//  CHCircularBufferDeque.h
//  CHDataStructures
//
//  Copyright © 2009-2021, Quinn Taylor
//

#import <CHDataStructures/CHDeque.h>
#import <CHDataStructures/CHCircularBuffer.h>

/**
 @file CHCircularBufferDeque.h
 A simple CHDeque implemented using a CHCircularBuffer.
 */

/**
 A simple CHDeque implemented using a CHCircularBuffer.
 */
@interface CHCircularBufferDeque : CHCircularBuffer <CHDeque>

@end
