//
//  RKPathTemplateTests.m
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

#import <SenTestingKit/SenTestingKit.h>
#define EXP_SHORTHAND
#import "Expecta.h"
#import <RKSupport/RKPathTemplate.h>

@interface RKPathTemplate ()
BOOL RKStringHasBraceCharacters(NSString *string);
BOOL RKIsValidSetOfVariables(NSArray *variables);
@end

@interface RKPathTemplateTests : SenTestCase
@end

@implementation RKPathTemplateTests

- (void)testStringHasBraceCharacters
{
    expect(RKStringHasBraceCharacters(@"")).to.beFalsy();
    expect(RKStringHasBraceCharacters(nil)).to.beFalsy();
    expect(RKStringHasBraceCharacters(@"jfkasl;d")).to.beFalsy();
    expect(RKStringHasBraceCharacters(@"{")).to.beTruthy();
    expect(RKStringHasBraceCharacters(@"}")).to.beTruthy();
    expect(RKStringHasBraceCharacters(@"{}")).to.beTruthy();
}

- (void)testVariablesStringInArrayAreValid
{
    expect(^{ RKIsValidSetOfVariables(@[ @"", @"", @""]); }).to.raise(NSInvalidArgumentException);
    expect(^{ RKIsValidSetOfVariables(@[ @"!@#$%^", @")(*!@#$", @"^$%@$@#$"]); }).to.raise(NSInvalidArgumentException);
    expect(^{ RKIsValidSetOfVariables(@[ @"{!@#$%^}", @"{)(*!@#$}", @"{^$%@$@#$}"]); }).to.raise(NSInvalidArgumentException);
    expect(^{ RKIsValidSetOfVariables(@[]); }).toNot.raise(NSInvalidArgumentException);
    expect(^{ RKIsValidSetOfVariables(@[ @"one", @"two", @"three" ]); }).toNot.raise(NSInvalidArgumentException);
    expect(^{ RKIsValidSetOfVariables(@[ @"one", @"two", @"three" ]); }).to.beTruthy();
    expect(^{ RKIsValidSetOfVariables(@[ @"variable_one", @"variable_two", @"variable_three" ]); }).toNot.raise(NSInvalidArgumentException);
    expect(^{ RKIsValidSetOfVariables(@[ @"variable_one", @"variable_two", @"variable_three" ]); }).to.beTruthy();
    expect(^{ RKIsValidSetOfVariables(@[ @"variable-one", @"variable-two", @"variable-three" ]); }).to.raise(NSInvalidArgumentException);
}

- (void)testInitThrowsInvalidExceptionWithNilString
{
    expect(^{ (void)[[RKPathTemplate alloc] init]; }).to.raise(NSInternalInconsistencyException);
    expect(^{ (void)[RKPathTemplate new]; }).to.raise(NSInternalInconsistencyException);
    expect(^{ (void)[RKPathTemplate pathTemplateWithString:nil]; }).to.raise(NSInvalidArgumentException);
    expect(^{ (void)[RKPathTemplate pathTemplateWithString:@""]; }).to.raise(NSInvalidArgumentException);
}

- (void)testInitThrowsInvalidExceptionWithStringComposedOfWhitespace
{
    expect(^{ (void)[RKPathTemplate pathTemplateWithString:@"         "]; }).to.raise(NSInvalidArgumentException);
}

- (void)testClassInitializer
{
    expect([RKPathTemplate pathTemplateWithString:@"/{test}"]).toNot.beNil();
}

- (void)testIsEqual
{
    expect([[RKPathTemplate pathTemplateWithString:@"/static_segment/{variable_segment}/"] isEqual:[RKPathTemplate pathTemplateWithString:@"/static_segment/{variable_segment}/"]]).to.beTruthy();
    expect([[RKPathTemplate pathTemplateWithString:@"/static_segment/{variable_segment}/"] isEqual:[RKPathTemplate pathTemplateWithString:@"/static_segment/{different_segment}/"]]).to.beFalsy();
}

- (void)testHash
{
    RKPathTemplate *template1 = [RKPathTemplate pathTemplateWithString:@"/static_segment/{variable_segment}/"];
    RKPathTemplate *template2 = [RKPathTemplate pathTemplateWithString:@"/static_segment/{variable_segment}/"];
    expect([template1 hash]).to.equal([template2 hash]);
    template2 = [RKPathTemplate pathTemplateWithString:@"/static_segment/{different_segment}/"];
    expect([template1 hash]).toNot.equal([template2 hash]);
}

#pragma mark - NSCoding

-(void)testNSCodingProtocol
{
    RKPathTemplate *template1 = [RKPathTemplate pathTemplateWithString:@"/static_segment/{variable_segment_one}/"];
    RKPathTemplate *template2 = [RKPathTemplate pathTemplateWithString:@"/static_segment/{variable_segment_two}/"];
    NSArray *templates = @[ template1, template2];
    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:templates];
    [[NSUserDefaults standardUserDefaults] setObject:archivedData forKey:@"templates"];
    NSData *unarchivedData = [[NSUserDefaults standardUserDefaults] objectForKey:@"templates"];
    NSArray *unarchivedTemplates = [NSKeyedUnarchiver unarchiveObjectWithData:unarchivedData];
    expect(templates).to.equal(unarchivedTemplates);
}

- (void)testParsingStringWithoutVariables
{
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/variable"];
    expect(template.variables).to.beEmpty();
}

- (void)testParsingStringComposedEntirelyOfVariable
{
    expect(^{ [RKPathTemplate pathTemplateWithString:@"/{variable}"]; }).notTo.raise(NSInvalidArgumentException);
}

- (void)testParsingVariableWithoutNameRaisesException
{
    expect(^{ [RKPathTemplate pathTemplateWithString:@"/{}"]; }).to.raiseWithReason(NSInvalidArgumentException, @"Invalid path template: '{}' is not a valid variable specifier.");
}

- (void)testParsingUnopenedVariableAtEndOfStringRaisesException
{
    expect(^{ [RKPathTemplate pathTemplateWithString:@"/variable}"]; }).to.raiseWithReason(NSInvalidArgumentException, @"Invalid path template: Unopened variable encountered. A '}' character must be preceded by a '{' character.");
}

- (void)testParsingUnopenedVariableRaisesException
{
    expect(^{ [RKPathTemplate pathTemplateWithString:@"/variable}/whatever"]; }).to.raiseWithReason(NSInvalidArgumentException, @"Invalid path template: Unopened variable encountered. A '}' character must be preceded by a '{' character.");
}

- (void)testParsingUnclosedVariableRaisesException
{
    expect(^{ [RKPathTemplate pathTemplateWithString:@"/{variable"]; }).to.raiseWithReason(NSInvalidArgumentException, @"Invalid path template: Unclosed variable encountered. A '{' character must be followed by a '}' character.");
}

- (void)testParsingDuplicatedVariableNameRaisesException
{
    expect(^{ [RKPathTemplate pathTemplateWithString:@"/{variable}/{variable}/end"]; }).to.raiseWithReason(NSInvalidArgumentException, @"Invalid path template: variable names must be unique.");
}

- (void)testParsingUnclosedCurlyBraceRaisesException
{
    expect(^{ [RKPathTemplate pathTemplateWithString:@"/{first_variable/{second_variable}"]; }).to.raise(NSInvalidArgumentException);
}

- (void)testParsingClosedBraceThatWasNotOpenedRaisesException
{
    expect(^{ [RKPathTemplate pathTemplateWithString:@"/first_variable}"]; }).to.raise(NSInvalidArgumentException);
}

- (void)testParsingVariableWithInvalidOperatorRaisesException
{
    expect(^{ [RKPathTemplate pathTemplateWithString:@"/{++var}"]; }).to.raise(NSInvalidArgumentException);
}

- (void)testParsingVariableWithInvalidVariableKeyRaisesException
{
    expect(^{ [RKPathTemplate pathTemplateWithString:@"/{var-name}"]; }).to.raise(NSInvalidArgumentException);
}

- (void)testThatAttemptToParseComponentContainingTwoVariablesRaisesException
{
    expect(^{ [RKPathTemplate pathTemplateWithString:@"/{variable1}_{variable2}"]; }).to.raiseWithReason(NSInvalidArgumentException, @"Invalid path template: A path component can only contain a single variable specifier.");
}

- (void)testVariablesAreCorrectlyParsed
{
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/{first_variable}/{second_variable}/{third_variable}.json"];
    expect([[template variables] containsObject:@"first_variable"]).to.equal(YES);
    expect([[template variables] containsObject:@"second_variable"]).to.equal(YES);
    expect([[template variables] containsObject:@"third_variable"]).to.equal(YES);
    template = [RKPathTemplate pathTemplateWithString:@"/first_variable/second_variable/third_variable.json"];
    expect([template variables]).to.beEmpty();
}

#pragma mark - String Expansion

- (void)testThatExpandWithVariablesWithNil
{
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/{variable}"];
    expect(^{ [template expandWithVariables:nil]; }).to.raise(NSInvalidArgumentException);
}

- (void)testThatExpandWithVariablesAcceptsEmptyDictionaryWithStaticPath
{
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/variable"];
    expect(^{ [template expandWithVariables:@{}]; }).toNot.raise(NSInvalidArgumentException);
}

- (void)testThatExpandWithVariablesWithMissingVariableKey
{
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/{first_segment}/{second_segment}"];
    NSDictionary *variables = @{ @"first_segment" : @"something" };
    expect(^{ [template expandWithVariables:variables]; }).to.raise(NSInvalidArgumentException);
}

- (void)testThatExpandingtoStringWithNullExpandsToEmptyString
{
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/{first_segment}"];
    NSDictionary *variables1 = @{ @"first_segment" : @"" };
    NSDictionary *variables2 = @{ @"first_segment" : [NSNull null] };
    expect([[template expandWithVariables:variables1] isEqualToString:[template expandWithVariables:variables2]]).to.equal(YES);
}

- (void)testThatExpandingtoStringWithUnknownVariableKeyThrowsException
{
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/{variable}"];
    expect(^{ [template expandWithVariables:@{ @"something" : @"wrong" }]; }).to.raise(NSInvalidArgumentException);
}

- (void)testThatExpandingToStringReturnsExpectedString
{
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/{variable}"];
    expect([template expandWithVariables:@{ @"variable" : @"correct" }]).to.equal(@"/correct");
}

- (void)testExpandingToStringFromInterpolatedObjects
{
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/people/{name}/{age}"];
    NSString *interpolatedPath = [template expandWithVariables:@{ @"name" : @"CuddleGuts",
                                                                  @"age" : [NSNumber numberWithInt:6] }];
    expect(interpolatedPath).to.equal(@"/people/CuddleGuts/6");
}

#pragma mark - Path Matching

- (void)testShouldMatchPathsWithoutQueryArguments
{
    NSDictionary *arguments;
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"github.com/{username}"];
    BOOL matches = [template matchesPath:@"github.com/jverkoey" variables:&arguments];
    expect(matches).to.equal(YES);
    expect(arguments).to.equal(@{ @"username": @"jverkoey" });
}

- (void)testShouldMatchPathsThatAreTheSameAndAreGreaterThanOneComponentsLong
{
    NSDictionary *arguments;
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/hi/bye"];
    BOOL matches = [template matchesPath:@"/hi/bye" variables:&arguments];
    expect(matches).to.equal(YES);
    expect(arguments).to.beEmpty();
}

- (void)testShouldMatchPathsWithoutAnyArguments
{
    NSDictionary *arguments;
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/metadata"];
    BOOL matches = [template matchesPath:@"/metadata" variables:&arguments];
    expect(matches).to.equal(YES);
    expect(arguments).to.beEmpty();
}

- (void)testShouldPerformTwoMatchesInARow
{
    NSDictionary *arguments;
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/metadata/{apikey}"];
    BOOL matches = [template matchesPath:@"/metadata/{stateID}" variables:&arguments];
    expect(matches).to.equal(NO);
    expect(arguments).to.equal(@{ @"apikey" : @"{stateID}" });
    matches = [template matchesPath:@"/metadata/12321431" variables:&arguments];
    expect(matches).to.equal(YES);
    expect(arguments).to.equal(@{ @"apikey": @"12321431" });
}

- (void)testMatchingPathWithTrailingSlashAndQueryThrowsException
{
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/api/v1/organizations/"];
    expect(^{ [template matchesPath:@"/api/v1/organizations/?client_search=t" variables:nil]; }).to.raise(NSInvalidArgumentException);
}

- (void)testMatchingPathPatternWithTrailingSlash
{
    NSDictionary *arguments;
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/api/v1/organizations/{identifier}/"];
    BOOL matches = [template matchesPath:@"/api/v1/organizations/1/" variables:&arguments];
    expect(matches).to.equal(YES);
    expect(arguments).to.equal(@{ @"identifier": @"1" });
}

- (void)testMatchingPathPatternWithTrailingSlashAndWithoutTrailingSlashAreSame
{
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/api/"];
    NSDictionary *arguments = @{};
    BOOL matches = [template matchesPath:@"/api" variables:&arguments];
    expect(matches).to.equal(YES);
}

- (void)testMatchingPathPatternWithLeadingSlashAndWithoutLeadingSlashAreDifferent
{
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/api"];
    NSDictionary *arguments = @{};
    BOOL matches = [template matchesPath:@"api" variables:&arguments];
    expect(matches).to.equal(NO);
}

- (void)testThatMatchingPathPatternsDoesNotMatchPathsShorterThanTheInput
{
    NSString *path = @"/categories/some-category-name/articles/the-article-name";
    RKPathTemplate *template1 = [RKPathTemplate pathTemplateWithString:@"/categories"];
    expect([template1 matchesPath:path variables:nil]).to.equal(NO);
    RKPathTemplate *template2 = [RKPathTemplate pathTemplateWithString:@"/categories/{categoryName}"];
    expect([template2 matchesPath:path variables:nil]).to.equal(NO);
    RKPathTemplate *template3 = [RKPathTemplate pathTemplateWithString:@"/categories/some-category-name/articles/{articleSlug}"];
    expect([template3 matchesPath:path variables:nil]).to.equal(YES);
}

#pragma mark - NSCopying

- (void)testCopy
{
    RKPathTemplate *template = [RKPathTemplate pathTemplateWithString:@"/{first_variable}/{second_variable}/{third_variable}.json"];
    expect([[template variables] containsObject:@"first_variable"]).to.equal(YES);
    expect([[template variables] containsObject:@"second_variable"]).to.equal(YES);
    expect([[template variables] containsObject:@"third_variable"]).to.equal(YES);
    RKPathTemplate *copy = [template copy];
    expect([[copy variables] containsObject:@"first_variable"]).to.equal(YES);
    expect([[copy variables] containsObject:@"second_variable"]).to.equal(YES);
    expect([[copy variables] containsObject:@"third_variable"]).to.equal(YES);
}

@end
