//
//  AbstractTests.h
//  template_ios_project
//
//  Created by Lanlan Song on 12-3-27.
//  Copyright (c) 2012年 Cybercom. All rights reserved.
//

//  Logic unit tests contain unit test code that is designed to be linked into an independent test executable.
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

/*
 OCHamcrest Predefined matchers
 ///////////////////////////////////
 Object
 -----------------------------------
 conformsTo - match object that conforms to protocol
 equalTo - match equal object
 hasDescription - match object's -description
 hasProperty - match return value of method with given name
 instanceOf - match object type
 isA - match object type precisely, no subclasses
 nilValue, notNilValue - match nil, or not nil
 sameInstance - match same object
 ///////////////////////////////////
 Number
 -----------------------------------
 closeTo - match number close to a given value
 equalTo<TypeName> - match number equal to a primitive number (such as equalToInt for an int)
 greaterThan, greaterThanOrEqualTo, lessThan, lessThanOrEqualTo - match numeric ordering
 ///////////////////////////////////
 Text
 -----------------------------------
 containsString - match part of a string
 endsWith - match the end of a string
 equalToIgnoringCase - match the complete string but ignore case
 equalToIgnoringWhitespace - match the complete string but ignore extra whitespace
 startsWith - match the beginning of a string
 stringContainsInOrder - match parts of a string, in relative order
 ///////////////////////////////////
 Logical
 -----------------------------------
 allOf - "and" together all matchers
 anyOf - "or" together all matchers
 anything - match anything (useful in composite matchers when you don't care about a particular value)
 isNot - negate the matcher
 ///////////////////////////////////
 Collection
 -----------------------------------
 contains - exactly match the entire collection
 containsInAnyOrder - match the entire collection, but in any order
 hasCount - match number of elements against another matcher
 hasCountOf - match collection with given number of elements
 hasEntries - match dictionary with list of key-value pairs
 hasEntry - match dictionary containing a key-value pair
 hasItem - match if given item appears in the collection
 hasItems - match if all given items appears in the collection, in any order
 hasKey - match dictionary with a key
 hasValue - match dictionary with a value
 isEmpty - match empty collection
 onlyContains - match if collection's items appear in given list
 ///////////////////////////////////
 Decorator
 -----------------------------------
 describedAs - give the matcher a custom failure description
 is - decorator to improve readability - see Syntactic sugar, below
 
 */

#import <XCTest/XCTest.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

#define JS_CodeStopHere while (!isCodeStop) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]]

#define JS_CodeResume isCodeStop = YES

#define JS_CodeShouldNotGotHere XCTFail(@"Code_Should_Not_Got_Here");

@interface AbstractTests : XCTestCase{
  @protected
  BOOL isCodeStop;
}

- (void)before;

- (void)after;

/**
 * Begins the async operation watch.
 * @discussion Call before async operation begins.
 */
- (void)beginAsyncOperation;

- (void)beginAsyncOperationWithTimeout:(NSTimeInterval)timeout;

/**
 * Finishes the async operation watch, call to complete operation and prevent timeout.
 */
- (void)finishedAsyncOperation;

/**
 * Waits for the async operation to finish or returns as a timeout.
 * @return YES if the async operation timeout interval is exceeded, NO if the
 * async operation finished.
 */
- (BOOL)waitForAsyncOperationOrTimeoutWithInterval:(NSTimeInterval)interval;
- (BOOL)waitForAsyncOperationOrTimeoutWithDefaultInterval; // timeout: 10secs

- (void)assertAsyncOperationTimeout; // uses default interval

@end
