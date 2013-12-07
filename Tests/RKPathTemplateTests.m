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
NSUInteger RKNumberOfLeftBracesInString(NSString *string);
NSUInteger RKNumberOfRightBracesInString(NSString *string);
NSUInteger RKNumberOfSlashesInString(NSString *string);
NSArray *RKComponentsOfStringMatchingRegexPattern(NSString *string, NSString *pattern);
BOOL *RKStringHasBraceCharacters(NSString *string);
BOOL *RKVariableStringsInArrayAreValid(NSArray *variables);
@end

@interface RKPathTemplateTests : SenTestCase
@end

@implementation RKPathTemplateTests

- (void)testNumberOfLeftBracesInString
{
    expect(RKNumberOfLeftBracesInString(@"{")).to.equal(1);
}

- (void)testNumberOfRightBracesInString
{
    expect(RKNumberOfRightBracesInString(@"}")).to.equal(1);
}

- (void)testNumberOfSlashesInString
{
    expect(RKNumberOfSlashesInString(@"/")).to.equal(1);
}

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
    expect(^{ RKVariableStringsInArrayAreValid(@[ @"", @"", @""]); }).to.raise(NSInvalidArgumentException);
    expect(^{ RKVariableStringsInArrayAreValid(@[ @"!@#$%^", @")(*!@#$", @"^$%@$@#$"]); }).to.raise(NSInvalidArgumentException);
    expect(^{ RKVariableStringsInArrayAreValid(@[ @"{!@#$%^}", @"{)(*!@#$}", @"{^$%@$@#$}"]); }).to.raise(NSInvalidArgumentException);
    expect(^{ RKVariableStringsInArrayAreValid(@[]); }).toNot.raise(NSInvalidArgumentException);
    expect(^{ RKVariableStringsInArrayAreValid(@[ @"one", @"two", @"three" ]); }).toNot.raise(NSInvalidArgumentException);
    expect(^{ RKVariableStringsInArrayAreValid(@[ @"one", @"two", @"three" ]); }).to.beTruthy();
    expect(^{ RKVariableStringsInArrayAreValid(@[ @"variable_one", @"variable_two", @"variable_three" ]); }).toNot.raise(NSInvalidArgumentException);
    expect(^{ RKVariableStringsInArrayAreValid(@[ @"variable_one", @"variable_two", @"variable_three" ]); }).to.beTruthy();
    expect(^{ RKVariableStringsInArrayAreValid(@[ @"variable-one", @"variable-two", @"variable-three" ]); }).to.raise(NSInvalidArgumentException);
}

- (void)testComponentsOfStringMatchingPattern
{
    NSArray *matches = @[ @"one", @"two", @"three" ];
    NSString *pattern = @"\\{(.*?)\\}";
    expect(RKComponentsOfStringMatchingRegexPattern(@"/{one}/{two}/{three}", pattern)).to.equal(matches);
    expect([RKComponentsOfStringMatchingRegexPattern(@"/{one}/{two}/{three}", pattern) count]).to.equal(3);
    expect(RKComponentsOfStringMatchingRegexPattern(@"/one/two/three", pattern)).to.beEmpty();
}

- (void)testInitThrowsInvalidExceptionWithNilString
{
    expect(^{ (void)[[RKPathTemplate alloc] init]; }).to.raise(NSInternalInconsistencyException);
    expect(^{ (void)[RKPathTemplate new]; }).to.raise(NSInternalInconsistencyException);
    expect(^{ (void)[[RKPathTemplate alloc] initWithString:nil]; }).to.raise(NSInvalidArgumentException);
    expect(^{ (void)[[RKPathTemplate alloc] initWithString:@""]; }).to.raise(NSInvalidArgumentException);
}

- (void)testInitThrowsInvalidExceptionWithStringComposedOfWhitespace
{
    expect(^{ (void)[[RKPathTemplate alloc] initWithString:@"         "]; }).to.raise(NSInvalidArgumentException);
}

- (void)testClassInitializer
{
    expect([RKPathTemplate pathTemplateWithString:@"/{test}"]).toNot.beNil();
}

- (void)testIsEqual
{
    expect([[[RKPathTemplate alloc] initWithString:@"/static_segment/{variable_segment}/"] isEqual:[[RKPathTemplate alloc] initWithString:@"/static_segment/{variable_segment}/"]]).to.beTruthy();
    expect([[[RKPathTemplate alloc] initWithString:@"/static_segment/{variable_segment}/"] isEqual:[[RKPathTemplate alloc] initWithString:@"/static_segment/{different_segment}/"]]).to.beFalsy();
}

- (void)testHash
{
    RKPathTemplate *template1 = [[RKPathTemplate alloc] initWithString:@"/static_segment/{variable_segment}/"];
    RKPathTemplate *template2 = [[RKPathTemplate alloc] initWithString:@"/static_segment/{variable_segment}/"];
    expect([template1 hash]).to.equal([template2 hash]);
    template2 = [[RKPathTemplate alloc] initWithString:@"/static_segment/{different_segment}/"];
    expect([template1 hash]).toNot.equal([template2 hash]);
}

- (void)testVariablesAreCorrectlyParsed
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/{first_variable}/{second_variable}/{third_variable}.json"];
    expect([[template variables] containsObject:@"first_variable"]).to.equal(YES);
    expect([[template variables] containsObject:@"second_variable"]).to.equal(YES);
    expect([[template variables] containsObject:@"third_variable"]).to.equal(YES);
    template = [[RKPathTemplate alloc] initWithString:@"/first_variable/second_variable/third_variable.json"];
    expect([template variables]).to.beEmpty();
}

- (void)testErrorIsReturnedOnAttemptToParseTemplateWithUnclosedCurlyBrace
{
    expect(^{ (void)[[RKPathTemplate alloc] initWithString:@"/{first_variable"]; }).to.raise(NSInvalidArgumentException);
    expect(^{ (void)[[RKPathTemplate alloc] initWithString:@"/{first_variable/{second_variable}"]; }).to.raise(NSInvalidArgumentException);
}

- (void)testErrorIsReturnedOnAttemptToParseTemplateWithClosedBraceThatWasNotOpened
{
    expect(^{ (void)[[RKPathTemplate alloc] initWithString:@"/first_variable}"]; }).to.raise(NSInvalidArgumentException);
}

- (void)testErrorIsReturnedOnAttemptToParseVariableWithInvalidOperator
{
    expect(^{ (void)[[RKPathTemplate alloc] initWithString:@"/{++var}"]; }).to.raise(NSInvalidArgumentException);
}
-(void)testErrorIsReturnedOnAttemptToParseVariableWithInvalidVariableKey
{
    expect(^{ (void)[[RKPathTemplate alloc] initWithString:@"/{var-name}"]; }).to.raise(NSInvalidArgumentException);
}

#pragma mark - String Expansion

- (void)testThatExpandWithVariablesWithNil
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/{variable}"];
    expect(^{ [template expandWithVariables:nil]; }).to.raise(NSInvalidArgumentException);
}

- (void)testThatExpandWithVariablesAcceptsEmptyDictionaryWithStaticPath
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/variable"];
    expect(^{ [template expandWithVariables:@{}]; }).toNot.raise(NSInvalidArgumentException);
}

- (void)testThatExpandWithVariablesWithMissingVariableKey
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/{first_segment}/{second_segment}"];
    NSDictionary *variables = @{ @"first_segment" : @"something" };
    expect(^{ [template expandWithVariables:variables]; }).to.raise(NSInvalidArgumentException);
}

- (void)testThatExpandingtoStringWithNullExpandsToEmptyString
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/{first_segment}"];
    NSDictionary *variables1 = @{ @"first_segment" : @"" };
    NSDictionary *variables2 = @{ @"first_segment" : [NSNull null] };
    NSLog(@"%@ %@", [template expandWithVariables:variables1], [template expandWithVariables:variables2]);
    expect([[template expandWithVariables:variables1] isEqualToString:[template expandWithVariables:variables2]]).to.equal(YES);
}

- (void)testThatExpandingtoStringWithUnknownVariableKeyThrowsException
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/{variable}"];
    expect(^{ [template expandWithVariables:@{ @"something" : @"wrong" }]; }).to.raise(NSInvalidArgumentException);
}

- (void)testThatExpandingToStringReturnsExpectedString
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/{variable}"];
    expect([template expandWithVariables:@{ @"variable" : @"correct" }]).to.equal(@"/correct");
}

- (void)testExpandingToStringFromInterpolatedObjects
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/people/{name}/{age}"];
    NSString *interpolatedPath = [template expandWithVariables:@{ @"name" : @"CuddleGuts",
                                                                  @"age" : [NSNumber numberWithInt:6] }];
    expect(interpolatedPath).to.equal(@"/people/CuddleGuts/6");
}

#pragma mark - Path Matching

- (void)testShouldMatchPathsWithoutQueryArguments
{
    NSDictionary *arguments;
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"github.com/{username}"];
    BOOL matches = [template matchesPath:@"github.com/jverkoey" variables:&arguments];
    expect(matches).to.equal(YES);
    expect(arguments).to.equal(@{ @"username": @"jverkoey" });
}

- (void)testShouldMatchPathsWithoutAnyArguments
{
    NSDictionary *arguments;
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/metadata"];
    BOOL matches = [template matchesPath:@"/metadata" variables:&arguments];
    expect(matches).to.equal(YES);
    expect(arguments).to.beEmpty();
}

- (void)testShouldPerformTwoMatchesInARow
{
    NSDictionary *arguments;
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/metadata/{apikey}"];
    BOOL matches = [template matchesPath:@"/metadata/{stateID}" variables:&arguments];
    expect(matches).to.equal(NO);
    expect(arguments).to.equal(@{ @"apikey" : @"{stateID}" });
    matches = [template matchesPath:@"/metadata/12321431" variables:&arguments];
    expect(matches).to.equal(YES);
    expect(arguments).to.equal(@{ @"apikey": @"12321431" });
}

- (void)testMatchingPathWithTrailingSlashAndQueryThrowsException
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/api/v1/organizations/"];
    expect(^{ [template matchesPath:@"/api/v1/organizations/?client_search=t" variables:nil]; }).to.raise(NSInvalidArgumentException);
}

- (void)testMatchingPathPatternWithTrailingSlash
{
    NSDictionary *arguments;
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/api/v1/organizations/{identifier}/"];
    BOOL matches = [template matchesPath:@"/api/v1/organizations/1/" variables:&arguments];
    expect(matches).to.equal(YES);
    expect(arguments).to.equal(@{ @"identifier": @"1" });
}

- (void)testMatchingPathPatternWithTrailingSlashAndWithoutTrailingSlashAreSame
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/api/"];
    NSDictionary *arguments = @{};
    BOOL matches = [template matchesPath:@"/api" variables:&arguments];
    expect(matches).to.equal(YES);
}

- (void)testMatchingPathPatternWithLeadingSlashAndWithoutLeadingSlashAreDifferent
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/api"];
    NSDictionary *arguments = @{};
    BOOL matches = [template matchesPath:@"api" variables:&arguments];
    expect(matches).to.equal(NO);
}

- (void)testThatMatchingPathPatternsDoesNotMatchPathsShorterThanTheInput
{
    NSString *path = @"/categories/some-category-name/articles/the-article-name";
    RKPathTemplate *template1 = [[RKPathTemplate alloc] initWithString:@"/categories"];
    expect([template1 matchesPath:path variables:nil]).to.equal(NO);
    RKPathTemplate *template2 = [[RKPathTemplate alloc] initWithString:@"/categories/{categoryName}"];
    expect([template2 matchesPath:path variables:nil]).to.equal(NO);
    RKPathTemplate *template3 = [[RKPathTemplate alloc] initWithString:@"/categories/some-category-name/articles/{articleSlug}"];
    expect([template3 matchesPath:path variables:nil]).to.equal(YES);
}

@end