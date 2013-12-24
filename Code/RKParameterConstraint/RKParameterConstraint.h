//
//  RKParameterConstraint.h
//  RestKit
//
//  Created by Kurry Tran on 12/8/13.
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
 Optional dictionary key that passes an array of parameter strings in the `constraintsDictionary`, that
 allow for parameters to be optional, when evaluating the array of contraints.
 */
extern NSString *const RKOptionalParametersKey;
/**
 Optional dictionary key that passes an array of required parameters strings are passed in the `constraintsDictionary`,
 that allow for parameters to be required, when evaluating the an array of constraints.
 */
extern NSString *const RKRequiredParametersKey;
/**
 The error domain for RKParameterConstraint generated errors.
 */
extern NSString * const RKParameterConstraintErrorDomain;

@interface RKParameterConstraint : NSObject <NSCopying, NSCoding>
/**
 Returns the name of the receiver.
 @return Returns the name of the receiver.
 */
@property (nonatomic, copy, readonly) NSString *parameter;
/**
 Returns a boolean value indicating whether the receiver is an optional constraint.
 @return Returns a boolean value indicating whether the receiver is an optional constraint.
 */
@property (nonatomic, assign, getter = isOptional) BOOL optional;
/** Initializes the receiver with a given parameter and associated value. This is the designated initializer
 for `RKParameterConstraint`.
 @param parameter A parameter key used to match values when evaluating constraints.
 @param value A value which can be an exact non-empty NSString, a non-empty NSSet or non-empty NSString of strings, 
 or a NSRegularExpression matching values.
 @return Returns a new RKParameterConstraint with the given parameter and associated value.
 */
+ (instancetype)constraintWithParameter:(NSString *)parameter value:(id)value;
/**
 Creates an NSArray of RKParameterContraints with the given `constraintsDictionary`.
 Example:
 
 NSDictionary *constraintsDictionary = @{ @"action": @[ @"search", @"browse"],
                                    @"user_id": [NSRegularExpression regularExpressionWithPattern:@"[\d]+" options:0 error:nil]
                                    RKOptionalParametersKey: @[ @"category_id" ],
                                    RKRequiredParametersKey: @"store_id" };
 [RKParameterConstraint constraintsWithDictionary:constraintsDictionary];
 
 @param constraintsDictionary The dictionary of key-value pairs containing the parameter name and associated value to be used in the constraint.
 @return An NSArray containing RKParameterContraints created from the `constraintsDictionary`.
 */
+ (NSArray *)constraintsWithDictionary:(NSDictionary *)constraintsDictionary;
/**
 Returns a boolean value indicating whether the given dictionary of parameters, satisfies the given constraints.
 
 @param constraints A non-empty array of RKParameterContraints to be evaluated.
 @param parameters A dictionary of parameters to evaluate the `constraints` array against.
 @return A boolean value indicating if all `constraints` were satisfied by the given `parameters`.
 */
+ (BOOL)areConstraints:(NSArray *)constraints satisfiedByParameters:(NSDictionary *)parameters;
/**
 Evaluates the given dictionary of parameters against the receiver and returns a Boolean value indicating if the constraint is satisfied.
 
 @param parameters A dictionary of parameters to evaluate the receiver against.
 @return A boolean value indicating if the given `parameters` satisfies the receivers constraints. 
 */
- (BOOL)satisfiedByParameters:(NSDictionary *)parameters;

@end

