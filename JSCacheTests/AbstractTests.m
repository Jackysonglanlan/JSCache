//
//  AbstractTests.m
//  template_ios_project
//
//  Created by Lanlan Song on 12-3-27.
//  Copyright (c) 2012年 Cybercom. All rights reserved.
//
/*
 OCHamcrest comes with a library of useful matchers:
 
 Object
 conformsTo - match object that conforms to protocol
 equalTo - match equal object
 hasDescription - match object's -description
 hasProperty - match return value of method with given name
 instanceOf - match object type
 nilValue, notNilValue - match nil, or not nil
 sameInstance - match same object
 
 Number
 closeTo - match number close to a given value
 equalTo<TypeName> - match number equal to a primitive number (such as equalToInt for an int)
 greaterThan, greaterThanOrEqualTo, lessThan, lessThanOrEqualTo - match numeric ordering
 
 Text
 containsString - match part of a string
 endsWith - match the end of a string
 equalToIgnoringCase - match the complete string but ignore case
 equalToIgnoringWhitespace - match the complete string but ignore extra whitespace
 startsWith - match the beginning of a string
 stringContainsInOrder - match parts of a string, in relative order
 
 Logical
 allOf - "and" together all matchers
 anyOf - "or" together all matchers
 anything - match anything (useful in composite matchers when you don't care about a particular value)
 isNot - negate the matcher
 
 Collection
 contains - exactly match the entire collection
 containsInAnyOrder - match the entire collection, but in any order
 empty - match empty collection
 hasCount - match number of elements against another matcher
 hasCountOf - match collection with given number of elements
 hasEntries - match dictionary with list of key-value pairs
 hasEntry - match dictionary containing a key-value pair
 hasItem - match if given item appears in the collection
 hasItems - match if all given items appear in the collection, in any order
 hasKey - match dictionary with a key
 hasValue - match dictionary with a value
 onlyContains - match if collections's items appear in given list
 
 Decorator
 describedAs - give the matcher a custom failure description
 is - decorator to improve readability - see Syntactic sugar below

 */

#import "AbstractTests.h"

@implementation AbstractTests{
  dispatch_semaphore_t _networkSemaphore;
  BOOL _didTimeout;
}

#pragma mark - life cycle

- (void)before{
  
}

- (void)after{
  
}

#pragma mark - utils


- (void)beginAsyncOperation{
  _didTimeout = NO;
  _networkSemaphore = dispatch_semaphore_create(0);
}

- (void)beginAsyncOperationWithTimeout:(NSTimeInterval)timeout{
    [self beginAsyncOperation];
    [self waitForAsyncOperationOrTimeoutWithInterval:timeout];
}

- (void)finishedAsyncOperation{
  _didTimeout = NO;
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeoutAsyncOperation) object:nil];
  
  dispatch_semaphore_signal(_networkSemaphore);
  dispatch_release(_networkSemaphore);
}

- (BOOL)waitForAsyncOperationOrTimeoutWithDefaultInterval{
  return [self waitForAsyncOperationOrTimeoutWithInterval:10];
}

- (BOOL)waitForAsyncOperationOrTimeoutWithInterval:(NSTimeInterval)interval{
  [self performSelector:@selector(timeoutAsyncOperation) withObject:nil afterDelay:interval];
  
  // wait for the semaphore to be signaled (triggered)
  while (dispatch_semaphore_wait(_networkSemaphore, DISPATCH_TIME_NOW)){
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
  }
  
  return _didTimeout;
}

- (void)timeoutAsyncOperation{
  _didTimeout = YES;
  dispatch_semaphore_signal(_networkSemaphore);
  dispatch_release(_networkSemaphore);
  XCTFail(@"Async operation timed out."); // auto-fail
}

- (void)assertAsyncOperationTimeout{
  assertThatBool([self waitForAsyncOperationOrTimeoutWithDefaultInterval], equalToBool(NO));
}

- (void)setUp{
  [self before];
}

- (void)tearDown{
  [self after];
}

@end
