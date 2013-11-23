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

+ (instancetype)pathTemplateWithString:(NSString *)string;

// Designated initializer. Vanilla `init` should called `initWithString:nil`. A template that is empty or `nil` must raise an `NSInvalidArgumentException`
- (id)initWithString:(NSString *)string;

// Returns a set of strings specifying the variables of the receiver.
@property (nonatomic, readonly) NSSet *variables;

/**
 Returns `YES` on a successful match. `variables` arg is optional, but should be a dictionary of the
 */
- (BOOL)matchesPath:(NSString *)path variables:(NSDictionary **)variables;
- (NSString *)expandWithVariables:(NSDictionary *)variables;

@end
