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
#import "RKPathTemplate.h"

@interface RKPathTemplateTests : SenTestCase
@end

@implementation RKPathTemplateTests

- (void)testInitThrowsInvalidExceptionWithNilString
{
    expect(^{ (void)[[RKPathTemplate alloc] init]; }).to.raise(NSInvalidArgumentException);
    expect(^{ (void)[RKPathTemplate new]; }).to.raise(NSInvalidArgumentException);
    expect(^{ (void)[[RKPathTemplate alloc] initWithString:nil]; }).to.raise(NSInvalidArgumentException);
    expect(^{ (void)[[RKPathTemplate alloc] initWithString:@""]; }).to.raise(NSInvalidArgumentException);
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
    expect([template variables]).toNot.beEmpty();
    NSSet *set = [NSSet setWithObjects:@"first_variable", @"second_variable", @"third_variable", nil];
    expect([template variables]).to.equal(set);
    template = [[RKPathTemplate alloc] initWithString:@"/first_variable/second_variable/third_variable.json"];
    expect([template variables]).to.beEmpty();
}

- (void)testErrorIsReturnedOnAttemptToParseTemplateWithUnclosedCurlyBrace
{
    expect(^{ (void)[[RKPathTemplate alloc] initWithString:@"/{first_variable"]; }).to.raise(@"NSInvalidArgumentException");
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

- (void)testThatExpandingToStringWithErrorThrowsException
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/{variable}"];
    expect(^{ [template expandWithVariables:nil]; }).to.raise(NSInvalidArgumentException);
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
    expect(arguments).to.beNil();
    matches = [template matchesPath:@"/metadata/12321431" variables:&arguments];
    expect(matches).to.equal(YES);
    expect(arguments).to.equal(@{ @"apikey": @"12321431" });
}

- (void)testMatchingPathWithTrailingSlashAndQuery
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/api/v1/organizations/"];
    expect([template matchesPath:@"/api/v1/organizations/?client_search=t" variables:nil]).to.equal(YES);
}

- (void)testMatchingPathPatternWithTrailingSlash
{
    NSDictionary *arguments;
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/api/v1/organizations/{identifier}/"];
    BOOL matches = [template matchesPath:@"/api/v1/organizations/1/" variables:&arguments];
    expect(matches).to.equal(YES);
    expect(arguments).to.equal(@{ @"identifier": @"1" });
}

- (void)testMatchingPathPatternWithTrailingSlashAndQueryParameters
{
    RKPathTemplate *template = [[RKPathTemplate alloc] initWithString:@"/api/v1/organizations/"];
    expect([template matchesPath:@"/api/v1/organizations/?client_search=s" variables:nil]).to.equal(YES);
}

- (void)testThatMatchingPathPatternsDoesNotMatchPathsShorterThanTheInput
{
    NSString *path = @"/categories/some-category-name/articles/the-article-name";
    RKPathTemplate *template1 = [[RKPathTemplate alloc] initWithString:@"/categories"];
    expect([template1 matchesPath:path variables:nil]).to.equal(NO);
    RKPathTemplate *template2 = [[RKPathTemplate alloc] initWithString:@"/categories/{categoryName}"];
    expect([template2 matchesPath:path variables:nil]).to.equal(NO);
    RKPathTemplate *template3 = [[RKPathTemplate alloc] initWithString:@"/categories/{categorySlug}/articles/{articleSlug}"];
    expect([template3 matchesPath:path variables:nil]).to.equal(YES);
}

@end