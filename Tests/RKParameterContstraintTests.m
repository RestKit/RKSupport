//
//  RKParameterContstraintTests.m
//  RKSupportTests
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

#import <SenTestingKit/SenTestingKit.h>
#define EXP_SHORTHAND
#import "Expecta.h"
#import <RKSupport/RKParameterConstraint.h>

@interface RKParameterContstraintTests : SenTestCase
@end

@interface RKConstraintsValidator : NSObject
+ (BOOL)isValidParameter:(NSString *)parameter  error:(NSError **)error;
+ (BOOL)isValidValue:(id)value  error:(NSError **)error;
+ (BOOL)isValidDictionaryOfParameterConstraints:(NSDictionary *)constraints error:(NSError **)error;
@end

@implementation RKParameterContstraintTests

- (void)testIsValidParameter
{
    NSError *error;
    NSString *description;
    BOOL valid = [RKConstraintsValidator isValidParameter:@"" error:&error];
    description = [[error userInfo] objectForKey:NSLocalizedDescriptionKey];
    expect(valid).to.beFalsy();
    expect(description).to.equal(@"parameter string should not be `nil` or length zero.");
    valid = YES;
    valid = [RKConstraintsValidator isValidParameter:nil error:&error];
    description = [[error userInfo] objectForKey:NSLocalizedDescriptionKey];
    expect(valid).to.beFalsy();
    expect(description).to.equal(@"parameter string should not be `nil` or length zero.");
    valid = YES;
    valid = [RKConstraintsValidator isValidParameter:@"        " error:&error];
    description = [[error userInfo] objectForKey:NSLocalizedDescriptionKey];
    expect(valid).to.beFalsy();
    expect(description).to.equal(@"parameter string should not be composed of all whitespace.");
}

- (void)testIsValidValue
{
    expect([RKConstraintsValidator isValidValue:@1 error:nil]).to.beFalsy();
    expect([RKConstraintsValidator isValidValue:@"" error:nil]).to.beFalsy();
    expect([RKConstraintsValidator isValidValue:[NSRegularExpression regularExpressionWithPattern:@"" options:0 error:nil] error:nil]).to.beFalsy();
    NSArray *values = @[];
    expect([RKConstraintsValidator isValidValue:values error:nil]).to.beFalsy();
}

- (void)testCopy
{
    RKParameterConstraint *constraint1 = [[RKParameterConstraint constraintsWithDictionary:@{ @"animal": @"cat"}] firstObject];
    RKParameterConstraint *copy1 = [constraint1 copy];
    expect(constraint1).to.equal(copy1);
    expect([constraint1 isEqual:copy1]).to.beTruthy();
    
    NSArray *pets = @[ @"cat", @"dog", @"bunny"];
    RKParameterConstraint *constraint2 = [[RKParameterConstraint constraintsWithDictionary:@{ @"animal": pets}] firstObject];
    RKParameterConstraint *copy2 = [constraint2 copy];
    expect(constraint2).to.equal(copy2);
    expect([constraint2 isEqual:copy2]).to.beTruthy();
    
    RKParameterConstraint *constraint3 = [RKParameterConstraint constraintWithParameter:@"animal" value:[NSRegularExpression regularExpressionWithPattern:@"^(cat|dog|bunny)$" options:0 error:nil]];
    RKParameterConstraint *copy3 = [constraint3 copy];
    expect(constraint3).to.equal(copy3);
    expect([constraint3 isEqual:copy3]).to.beTruthy();
}

-(void)testNSCodingProtocol
{
    NSArray *constraints1 = [RKParameterConstraint constraintsWithDictionary:@{ @"parameter": @"value_one" }];
    NSArray *animals = @[ @"cat", @"dog", @"rabbit" ];
    NSDictionary *constraintsDictionary = @{ @"name" : @"kurry",
                                    @"favorite_animals" : animals,
                                    @"occupation" : @[ @"student", @"software engineer", @"unemployed"] };
    NSArray *constraints2 = [RKParameterConstraint constraintsWithDictionary:constraintsDictionary];
    NSArray *templates = @[ constraints1, constraints2];
    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:templates];
    [[NSUserDefaults standardUserDefaults] setObject:archivedData forKey:@"constraints"];
    NSData *unarchivedData = [[NSUserDefaults standardUserDefaults] objectForKey:@"constraints"];
    NSArray *unarchivedTemplates = [NSKeyedUnarchiver unarchiveObjectWithData:unarchivedData];
    expect(templates).to.equal(unarchivedTemplates);
}

- (void)testHash
{
    NSArray *pets = @[ @"cat", @"dog", @"bunny"];
    RKParameterConstraint *constraint1 = [[RKParameterConstraint constraintsWithDictionary:@{ @"animal": pets}] firstObject];
    RKParameterConstraint *constraint2 = [[RKParameterConstraint constraintsWithDictionary:@{ @"animal": pets}] firstObject];
    expect([constraint1 hash]).to.equal([constraint2 hash]);
}

- (void)testIsEqual
{
    NSArray *pets = @[ @"cat", @"dog", @"bunny"];
    RKParameterConstraint *constraint1 = [[RKParameterConstraint constraintsWithDictionary:@{ @"animal": pets}] firstObject];
    RKParameterConstraint *constraint2 = [[RKParameterConstraint constraintsWithDictionary:@{ @"animal": pets}] firstObject];
    expect(constraint1).to.equal(constraint2);
}

- (void)testIsValidDictionaryOfParameterConstraints
{
    NSArray *numbers = @[ @1, @2, @3];
    NSArray *strings = @[ @"one", @"two", @"three"];
    NSSet *setOfStrings = [NSSet setWithArray:strings];
    NSSet *setOfNumbers = [NSSet setWithArray:numbers];
    expect(^{ [RKConstraintsValidator isValidDictionaryOfParameterConstraints:nil error:nil]; }).to.raise(NSInvalidArgumentException);
    expect(^{ [RKConstraintsValidator isValidDictionaryOfParameterConstraints:@{} error:nil]; }).to.raise(NSInvalidArgumentException);
    expect([RKConstraintsValidator isValidDictionaryOfParameterConstraints:@{ @"parameter" : @1} error:nil]).to.beFalsy();
    expect([RKConstraintsValidator isValidDictionaryOfParameterConstraints:@{ @"parameter" : numbers} error:nil]).to.beFalsy();
    expect([RKConstraintsValidator isValidDictionaryOfParameterConstraints:@{ @"parameter" : setOfNumbers} error:nil]).to.beFalsy();
    expect([RKConstraintsValidator isValidDictionaryOfParameterConstraints:@{ @"parameter" : @"value"} error:nil]).to.beTruthy();
    expect([RKConstraintsValidator isValidDictionaryOfParameterConstraints:@{ @"parameter" : strings} error:nil]).to.beTruthy();
    expect([RKConstraintsValidator isValidDictionaryOfParameterConstraints:@{ @"parameter" : setOfStrings } error:nil]).to.beTruthy();
    NSDictionary *multipleConstraints = @{ @"parameter_one" : @"value",
                                           @"parameter_two" : strings,
                                           @"parameter_three" : setOfStrings};
    expect([RKConstraintsValidator isValidDictionaryOfParameterConstraints:multipleConstraints error:nil]).to.beTruthy();
    NSDictionary *multipleConstraintsWithBadConstraint = @{ @"parameter_one" : @"value",
                                           @"parameter_two" : strings,
                                           @"parameter_three" : setOfNumbers};
    expect([RKConstraintsValidator isValidDictionaryOfParameterConstraints:multipleConstraintsWithBadConstraint error:nil]).to.beFalsy();
}

- (void)testInitThrowsInvalidArgumentExceptionWithNilOrEmptyConstraints
{
    expect(^{ (void)[[RKParameterConstraint alloc] init]; }).to.raise(NSInternalInconsistencyException);
    expect(^{ (void)[RKParameterConstraint new]; }).to.raise(NSInternalInconsistencyException);
    expect(^{ (void)[RKParameterConstraint constraintsWithDictionary:nil]; }).to.raise(NSInvalidArgumentException);
    expect(^{ (void)[RKParameterConstraint constraintsWithDictionary:@{}]; }).to.raise(NSInvalidArgumentException);
}

- (void)testInitThrowsInvalidArgumentExceptionWithInvalidParameterConstraints
{
    NSArray *numbers = @[ @1, @2, @3 ];
    NSSet *setOfNumbers = [NSSet setWithArray:numbers];
    expect(^{ (void)[RKParameterConstraint constraintsWithDictionary:@{ @"parameter": @1 }]; }).to.raise(NSInvalidArgumentException);
    expect(^{ (void)[RKParameterConstraint constraintsWithDictionary:@{ @"parameter":  numbers }]; }).to.raise(NSInvalidArgumentException);
    expect(^{ (void)[RKParameterConstraint constraintsWithDictionary:@{ @"parameter":  setOfNumbers }]; }).to.raise(NSInvalidArgumentException);
}

- (void)testThatInitReturnsCorrectNumberOfParameterConstraints
{
    expect([[RKParameterConstraint constraintsWithDictionary:@{ @"parameter": @"value_one" }] count]).to.equal(1);
    NSArray *animals = @[ @"cat", @"dog", @"rabbit" ];
    NSDictionary *constraints1 = @{ @"name" : @"kurry",
                                    @"favorite_animals" : animals,
                                    @"occupation" : @[ @"student", @"software engineer", @"unemployed"] };
    expect([[RKParameterConstraint constraintsWithDictionary:constraints1] count]).to.equal(3);
}

- (void)testInstanceTypeInitThrowsInvalidArgumentExceptionWithNilorInvalidArguments
{
    expect(^{ (void)[RKParameterConstraint constraintWithParameter:nil value:nil]; }).to.raise(NSInvalidArgumentException);
    expect(^{ (void)[RKParameterConstraint constraintWithParameter:@"parameter" value:nil]; }).to.raise(NSInvalidArgumentException);
    expect(^{ (void)[RKParameterConstraint constraintWithParameter:nil value:@"missing_parameter"]; }).to.raise(NSInvalidArgumentException);
    expect(^{ (void)[RKParameterConstraint constraintWithParameter:@"parameter" value:@1]; }).to.raise(NSInvalidArgumentException);
    NSArray *badValues = @[ @1, @"value", @3];
    expect(^{ (void)[RKParameterConstraint constraintWithParameter:@"parameter" value:badValues]; }).to.raise(NSInvalidArgumentException);
}

- (void)testThatMatchingSingularValueSatisfiesConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @"search" }];
    NSDictionary *parameters = @{ @"action": @"search", @"category_id": @"1234" };
    expect([RKParameterConstraint areConstraints:constraints satisfiedByParameters:parameters]).to.beTruthy();
}

- (void)testThatNonMatchingSingularValueDoesNotSatisfyConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @"search" }];
    NSDictionary *parameters = @{ @"action": @"browse", @"category_id": @"1234" };
    expect([RKParameterConstraint areConstraints:constraints satisfiedByParameters:parameters]).to.beFalsy();
}

- (void)testThatMatchingMultipleValueSatisfiesConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"] }];
    NSDictionary *parameters = @{ @"action": @"browse", @"category_id": @"1234" };
    expect([RKParameterConstraint areConstraints:constraints satisfiedByParameters:parameters]).to.beTruthy();
}

- (void)testThatNonMatchingMultipleValueDoesNotSatisfiesConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"] }];
    NSDictionary *parameters = @{ @"action": @"browse", @"category_id": @"1234" };
    expect([RKParameterConstraint areConstraints:constraints satisfiedByParameters:parameters]).to.beTruthy();
}

- (void)testThatSatifiedByParametersThrowsExceptionWithNilDictionary
{
    RKParameterConstraint *constraint = [[RKParameterConstraint constraintsWithDictionary:@{ @"action": @"search" }] firstObject];
    expect(^{ (void)[constraint satisfiedByParameters:nil]; }).to.raise(NSInvalidArgumentException);
}

- (void)testThatSatifiedByParametersIsFalseWithNonExistentParameterKey
{
    RKParameterConstraint *constraint = [[RKParameterConstraint constraintsWithDictionary:@{ @"action": @"search" }] firstObject];
    expect([constraint satisfiedByParameters:@{ @"some_key" : @"doesn't exist" }]).to.beFalsy();
}

- (void)testThatSatifiedByParametersThrowsExceptionWithInvalidParameterValue
{
    RKParameterConstraint *constraint = [[RKParameterConstraint constraintsWithDictionary:@{ @"action": @"search" }] firstObject];
    expect(^{ (void)[constraint satisfiedByParameters:@{ @"action" : @1 }]; }).to.raise(NSInvalidArgumentException);
}

- (void)testThatMatchingSingularValueIsSatisfiedByParameters
{
    RKParameterConstraint *constraint = [[RKParameterConstraint constraintsWithDictionary:@{ @"action": @"search" }] firstObject];
    expect([constraint satisfiedByParameters:@{ @"action": @"search" }]).to.beTruthy();
}

- (void)testThatNonMatchingSingularValueIsNotSatisfiedByParameters
{
    RKParameterConstraint *constraint = [[RKParameterConstraint constraintsWithDictionary:@{ @"action": @"search" }] firstObject];
    expect([constraint satisfiedByParameters:@{ @"action": @"delete" }]).to.beFalsy();
}

- (void)testThatMatchingMultipleValueIsSatisfiedByParameters
{
    NSArray *pets = @[ @"cat", @"dog", @"bunny"];
    RKParameterConstraint *constraint = [[RKParameterConstraint constraintsWithDictionary:@{ @"animal": pets}] firstObject];
    expect([constraint satisfiedByParameters:@{ @"animal" : @"dog"}]).to.beTruthy();
}

- (void)testThatNonMatchingMultipleValueIsNotSatisfiedByParameters
{
    NSArray *pets = @[ @"cat", @"dog", @"bunny"];
    RKParameterConstraint *constraint = [[RKParameterConstraint constraintsWithDictionary:@{ @"animal": pets}] firstObject];
    NSDictionary *parameters = @{ @"animal": @"snake", @"category_id": @"1234" };
    expect([constraint satisfiedByParameters:parameters]).to.beFalsy();
}

- (void)testThatMatchingMissingParameterDoesNotSatisfyConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : @"none" }];
    NSDictionary *parameters = @{ @"action": @"browse", @"category_id": @"1234" };
    expect([RKParameterConstraint areConstraints:constraints satisfiedByParameters:parameters]).to.beFalsy();
}

- (void)testThatParametersMissingAParameterAreNotSatisfiedByParameters
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : @"none" }];
    NSDictionary *parameters = @{ @"action": @"browse", @"category_id": @"1234" };
    RKParameterConstraint *constraint = constraints[1];
    expect([constraint satisfiedByParameters:parameters]).to.beFalsy();
}

#pragma mark -
#pragma mark - Optional Parameters Test

- (void)testThatMissingOptionalParameterSatisfiesConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : @"none", RKOptionalParametersKey : @[ @"animals" ] }];
    NSDictionary *parameters = @{ @"action": @"browse", @"category_id": @"1234" };
    expect([RKParameterConstraint areConstraints:constraints satisfiedByParameters:parameters]).to.beTruthy();
    
    NSArray *exactConstraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : @[ @"cat", @"dog", @"none"], RKOptionalParametersKey : @[ @"animals" ] }];
    expect([RKParameterConstraint areConstraints:exactConstraints satisfiedByParameters:parameters]).to.beTruthy();
    
    NSArray *regexConstraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : [NSRegularExpression regularExpressionWithPattern:@"^(cat|dog|none)$" options:0 error:nil], RKOptionalParametersKey : @[ @"animals" ] }];
    expect([RKParameterConstraint areConstraints:regexConstraints satisfiedByParameters:parameters]).to.beTruthy();
}

- (void)testThatMatchingOptionalParameterSatisfiesConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : @"none", RKOptionalParametersKey : @[ @"animals" ] }];
    NSDictionary *parameters = @{ @"action": @"browse", @"animals": @"none" };
    expect([RKParameterConstraint areConstraints:constraints satisfiedByParameters:parameters]).to.beTruthy();
    
    NSArray *exactConstraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : @[ @"cat", @"dog", @"none"], RKOptionalParametersKey : @[ @"animals" ] }];
    expect([RKParameterConstraint areConstraints:exactConstraints satisfiedByParameters:parameters]).to.beTruthy();
    
    NSArray *regexConstraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : [NSRegularExpression regularExpressionWithPattern:@"^(cat|dog|none)$" options:0 error:nil], RKOptionalParametersKey : @[ @"animals" ] }];
    expect([RKParameterConstraint areConstraints:regexConstraints satisfiedByParameters:parameters]).to.beTruthy();
}

- (void)testThatNonMatchingOptionalParameterDoesNotSatisfyConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : @"none", RKOptionalParametersKey : @[ @"animals" ] }];
    NSDictionary *parameters = @{ @"action": @"browse", @"animals": @"dog" };
    expect([RKParameterConstraint areConstraints:constraints satisfiedByParameters:parameters]).to.beFalsy();
    
    NSArray *exactConstraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : @[ @"cat", @"none"], RKOptionalParametersKey : @[ @"animals" ] }];
    expect([RKParameterConstraint areConstraints:exactConstraints satisfiedByParameters:parameters]).to.beFalsy();
    
    NSArray *regexConstraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : [NSRegularExpression regularExpressionWithPattern:@"^(cat|none)$" options:0 error:nil], RKOptionalParametersKey : @[ @"animals" ] }];
    expect([RKParameterConstraint areConstraints:regexConstraints satisfiedByParameters:parameters]).to.beFalsy();
}

- (void)testOptionalParameterWithoutConstraintSatisfiesConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], RKOptionalParametersKey : @[ @"animals" ] }];
    NSDictionary *parameters = @{ @"action": @"browse", @"animals": @"none" };
    expect([RKParameterConstraint areConstraints:constraints satisfiedByParameters:parameters]).to.beTruthy();
}

#pragma mark -
#pragma mark - Required Parameters Test

- (void)testThatMissingRequiredParameterDoesSatisfiesConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], RKRequiredParametersKey : @[ @"animals" ] }];
    NSDictionary *parameters = @{ @"action": @"browse", @"category_id": @"1234" };
    expect([RKParameterConstraint areConstraints:constraints satisfiedByParameters:parameters]).to.beFalsy();
    
    NSArray *exactConstraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : @[ @"cat", @"dog", @"none"], RKRequiredParametersKey : @[ @"animals" ] }];
    expect([RKParameterConstraint areConstraints:exactConstraints satisfiedByParameters:parameters]).to.beFalsy();
    
    NSArray *regexConstraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : [NSRegularExpression regularExpressionWithPattern:@"^(cat|dog|none)$" options:0 error:nil], RKRequiredParametersKey : @[ @"animals" ] }];
    expect([RKParameterConstraint areConstraints:regexConstraints satisfiedByParameters:parameters]).to.beFalsy();
}

- (void)testThatMatchingRequiredParameterSatisfiesConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : @"none", RKRequiredParametersKey : @[ @"animals" ] }];
    NSDictionary *parameters = @{ @"action": @"browse", @"animals": @"none" };
    expect([RKParameterConstraint areConstraints:constraints satisfiedByParameters:parameters]).to.beTruthy();
    
    NSArray *exactConstraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : @[ @"cat", @"dog", @"none"], RKRequiredParametersKey : @[ @"animals" ] }];
    expect([RKParameterConstraint areConstraints:exactConstraints satisfiedByParameters:parameters]).to.beTruthy();
    
    NSArray *regexConstraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : [NSRegularExpression regularExpressionWithPattern:@"^(cat|dog|none)$" options:0 error:nil], RKRequiredParametersKey : @[ @"animals" ] }];
    expect([RKParameterConstraint areConstraints:regexConstraints satisfiedByParameters:parameters]).to.beTruthy();
}

- (void)testThatNonMatchingRequiredParameterDoesNotSatisfyConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : @"none", RKRequiredParametersKey : @[ @"animals" ] }];
    NSDictionary *parameters = @{ @"action": @"browse", @"animals": @"dog" };
    expect([RKParameterConstraint areConstraints:constraints satisfiedByParameters:parameters]).to.beFalsy();
    
    NSArray *exactConstraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : @[ @"cat", @"none"], RKRequiredParametersKey : @[ @"animals" ] }];
    expect([RKParameterConstraint areConstraints:exactConstraints satisfiedByParameters:parameters]).to.beFalsy();
    
    NSArray *regexConstraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], @"animals" : [NSRegularExpression regularExpressionWithPattern:@"^(cat|none)$" options:0 error:nil], RKRequiredParametersKey : @[ @"animals" ] }];
    expect([RKParameterConstraint areConstraints:regexConstraints satisfiedByParameters:parameters]).to.beFalsy();
}

- (void)testThatRequiredParameterWithoutConstraintSatisfiesConstraints
{
    NSArray *constraints = [RKParameterConstraint constraintsWithDictionary:@{ @"action": @[ @"search", @"browse"], RKRequiredParametersKey : @[ @"animals" ] }];
    NSDictionary *parameters = @{ @"action": @"browse", @"animals": @"none" };
    expect([RKParameterConstraint areConstraints:constraints satisfiedByParameters:parameters]).to.beTruthy();
}

#pragma mark -
#pragma mark - RKExactParameterConstraint

- (void)testExactParameterConstraintValues
{
    NSArray *pets = @[ @"cat", @"dog", @"bunny"];
    RKParameterConstraint *constraint = [[RKParameterConstraint constraintsWithDictionary:@{ @"animal": pets}] firstObject];
    NSDictionary *parameters = @{ @"animal" : @"dog"};
    expect([constraint satisfiedByParameters:parameters]).to.beTruthy();
    parameters = @{ @"animal" : @"cat"};
    expect([constraint satisfiedByParameters:parameters]).to.beTruthy();
    parameters = @{ @"animal" : @"bunny"};
    expect([constraint satisfiedByParameters:parameters]).to.beTruthy();
}

#pragma mark -
#pragma mark - RKRegularExpressionParameterConstraint

- (void)testThatRegularExpressionMatchingSingularValueIsSatisfiedByParameters
{
    RKParameterConstraint *constraint = [RKParameterConstraint constraintWithParameter:@"fruit" value:[NSRegularExpression regularExpressionWithPattern:@"^(apple)$" options:0 error:nil]];
    expect([constraint satisfiedByParameters:@{ @"fruit": @"apple" }]).to.beTruthy();
}

- (void)testThatRegularExpressionNonMatchingSingularValueIsNotSatisfiedByParameters
{
    RKParameterConstraint *constraint = [RKParameterConstraint constraintWithParameter:@"fruit" value:[NSRegularExpression regularExpressionWithPattern:@"^(apple)$" options:0 error:nil]];
    expect([constraint satisfiedByParameters:@{ @"fruit": @"delete" }]).to.beFalsy();
}

- (void)testThatRegularExpressionMatchingMultipleValueIsSatisfiedByParameters
{
    RKParameterConstraint *constraint = [RKParameterConstraint constraintWithParameter:@"animal" value:[NSRegularExpression regularExpressionWithPattern:@"^(cat|dog|bunny)$" options:0 error:nil]];
    expect([constraint satisfiedByParameters:@{ @"animal" : @"dog"}]).to.beTruthy();
}

- (void)testThatRegularExpressionNonMatchingMultipleValueIsNotSatisfiedByParameters
{
    RKParameterConstraint *constraint = [RKParameterConstraint constraintWithParameter:@"animal" value:[NSRegularExpression regularExpressionWithPattern:@"^(cat|dog|bunny)$" options:0 error:nil]];
    NSDictionary *parameters = @{ @"animal": @"snake", @"category_id": @"1234" };
    expect([constraint satisfiedByParameters:parameters]).to.beFalsy();
}

@end
