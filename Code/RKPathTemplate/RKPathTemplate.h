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
 The `RKPathTemplate` class provides an interface for matching and expanding path strings that contain variable components. A valid path template is a string of Unicode characters that contains zero or more embedded variable expressions, each expression being delimited by a matching pair of braces ('{', '}').  The path template may not include a '?' query delimiter and a variable name may only appear once. The syntax is a subset of the URI Template specification (see RFC 6570 http://tools.ietf.org/html/rfc6570) that omits support for query strings and variable expression operators in order to support symmetrical matching and expansion operations.
 
 # Path Matching
 
 An `RKPathTemplate` object can be evaluated against a given path string in order to determine if it matches and extract all variable components into a dictionary. Path templates are delimited into components by the slash ('/') character. A template will only positively match an input path with exactly the same number of path components. Each static path component of the input string must also exactly match the corresponding component of the template. To better understand the matching semantics, consider the table below:
 
 --------------------------------------------------------------------------------------------------------------------
 | Path Template                 | Input Path                   | Matches? | Variables                              |
 --------------------------------------------------------------------------------------------------------------------
 | /users                        | /users                       | YES      | @{}                                    |
 | /users                        | users                        | NO       | nil                                    |
 | /users                        | users/                       | NO       | nil                                    |
 | /users                        | friends                      | NO       | nil                                    |
 | /{variable}                   | /whatever                    | YES      | @{ @"variable": @"whatever" }          |
 | /users/{userID}               | /users/1234                  | YES      | @{ @"userID": @"1234" }                |
 | /users/{userID}               | /users                       | NO       | nil                                    |
 | /users/{userID}               | /users/1234/categories       | NO       | nil                                    |
 | /categories/{name}/posts/{id} | /categories/News/posts/12345 | YES      | @{ @"name": @"News", @"id": @"12345" } |
 --------------------------------------------------------------------------------------------------------------------
 
 # Path Expansion
 
 A `RKPathTemplate` object can be expanded into a full path by providing a dictionary of variables. The dictionary must contain an entry for each variable contained within the template. Variables in the given dictionary that are not used within the template being expanded are ignored. Each entry in the dictionary must have a key and value that is an `NSString` object or responds to the `stringValue` message. To better understand the expansion sematnics, consider the table below:
 
 -----------------------------------------------------------------------------------------
 | Path Template           | Variables                           | Path                  |
 -----------------------------------------------------------------------------------------
 | /users                  | @{ @"id": @"1234" }                 | /users                |
 | /users/{userID}         | @{ @"id": @"1234" }                 | /users/1234           |
 | /users/{userID}         | @{ @"name": @"Joe" }                | nil                   |
 | /posts/{id}/tags/{name} | @{ @"id": @321, @"name": @"funny" } | /posts/321/tags/funny |
 | /posts/{id}/tags/{name} | @{ @"name": @"funny" }              | nil                   |
 -----------------------------------------------------------------------------------------

 */
@interface RKPathTemplate : NSObject <NSCopying, NSCoding>

///------------------------------
/// @name Creating Path Templates
///------------------------------

/**
 Creates and returns a new path template object initialized with the given string.
 
 @param string The string with which to initialize the newly created path template object. Cannot be an empty string or `nil`, else an `NSInvalidArgumentException` exception will be raised.
 @return The newly created path template object.
 */
+ (instancetype)pathTemplateWithString:(NSString *)string;

///-----------------------------------
/// @name Accessing Template Variables
///-----------------------------------

/**
 Returns the set of variable names parsed from the template.
 
 For example, a path template of `@"/users/{userID}/categories/{categoryID}"` would return a set of variables containing `@"userID"` and `@"categoryID"`.
 */
@property (nonatomic, readonly) NSSet *variables;

///------------------------------------------
/// @name Matching Paths Against the Template
///------------------------------------------

/**
 Evaluates the given path against the receiver and returns a Boolean value indicating if the match was successful, optionally returning a dictionary of values keyed by variable name matched from the given path.

 @param path The path to evaluate against the receiver. Cannot be nil.
 @param variables A pointer to a dictionary object that will be set upon successful matching. May be nil.
 @return A Boolean value indicating if the match was successful.
 */
- (BOOL)matchesPath:(NSString *)path variables:(NSDictionary **)variables;

///----------------------------------------
/// @name Expanding Paths From the Template
///----------------------------------------

/**
 Expands the receiver into a full path string using the given dictionary of variables. If the dictionary does not contain an entry for each variable used in the template then `nil` is returned.
 
 @param variables The dictionary of variables with which to expand the receiver. The dictionary must be composed entirely of keys and values that are objects that are instances of `NSString` or are coercable into a string representation by calling `stringValue`, else an `NSInvalidArgumentException` is raised.
 @return A full path string expanded from the receiver using the given variables or `nil` if the template could not be expanded.
 */
- (NSString *)expandWithVariables:(NSDictionary *)variables;

@end
