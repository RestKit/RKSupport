//
//  RKPathTemplate.h
//  RestKit
//
//  Created by Kurry Tran on 11/23/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
/**
 Design Points:

 * This is a subset of the URI Template format. It does not support query parameters. Only paths and simple variables.
 * Templates are of the form "/static_segment/{variable_segment}/" vs old format of "/static/:variable"
 * Templates such as "/people/{personID}.json" should work.
 * Drop dependence on SOCKit. Use `NSScanner` or `NSRegularExpression` for underlying implementation.
 * Matches are exact. There must be the same number of segments in the pattern as the inputted path for a match to evaluate.
 * Should have a decent implementation of `isEqual:` and `hash` so that this can be used in a
 * This can be spun out into a standalone library. In fact you can build it in a seperate repository if you want.
 * Take a look at CSURITemplate to see what the full enchilada is like.
 * This replaces `RKPathMatcher`. See its implementation and test cases for reference
 */
@interface RKPathTemplate : NSObject <NSCopying, NSCoding>

/**
 Creates and returns a new path template object initialized with the given string.
 
 @param string The string with which to initialize the newly created path template object. Cannot be an empty string or `nil`, else an `NSInvalidArgumentException` exception will be raised.
 @return The newly created path template object.
 */
+ (instancetype)pathTemplateWithString:(NSString *)string;

/**
 Returns the set of variable names parsed from the template.
 
 For example, a path template of `@"/users/{userID}/categories/{categoryID}"` would return a set of variables containing `@"userID"` and `@"categoryID"`.
 */
@property (nonatomic, readonly) NSSet *variables;

/**
 Evaluates the given path against the receiver and returns a Boolean value indicating if the match was successful, optionally returning a dictionary of values keyed by variable name matched from the given path.

 @param path The path to evaluate against the receiver. Cannot be nil.
 @param variables A pointer to a dictionary object that will be set upon successful matching. May be nil.
 @return A Boolean value indicating if the match was successful.
 */
- (BOOL)matchesPath:(NSString *)path variables:(NSDictionary **)variables;

/**
 Expands the receiver into a full path string using the given dictionary of variables. If the dictionary does not contain an entry for each variable used in the template then `nil` is returned.
 
 @param variables The dictionary of variables with which to expand the receiver. The dictionary must be composed entirely of keys and values that are objects that are instances of `NSString` or are coercable into a string representation by calling `stringValue`, else an `NSInvalidArgumentException` is raised.
 @return A full path string expanded from the receiver using the given variables or `nil` if the template could not be expanded.
 */
- (NSString *)expandWithVariables:(NSDictionary *)variables;

@end
