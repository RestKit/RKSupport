//
//  RKPathTemplate.m
//  RestKit
//
//  Created by Kurry Tran on 11/23/13.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import "RKPathTemplate.h"

NSUInteger RKNumberOfSlashesInString(NSString *string)
{
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"/" options:NSRegularExpressionCaseInsensitive error:nil];
    });
    return [regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, [string length])];
}

BOOL RKIsValidSetOfVariables(NSSet *variables)
{
    NSMutableCharacterSet *parameterCharacterSet = [NSMutableCharacterSet alphanumericCharacterSet];
    [parameterCharacterSet addCharactersInString:@"._{}"];
    NSCharacterSet *invalidSet = [parameterCharacterSet invertedSet];
    for (NSString *variable in variables) {
        NSRange range = [variable rangeOfCharacterFromSet:invalidSet];
        if (range.location != NSNotFound || [variable length] == 0) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"The variable name:%@ is invalid. All characters should be alphanumeric characters or [ . , - , _ ] symbols.", variable] userInfo:nil];
        }
    }
    return YES;
}

BOOL *RKStringHasBraceCharacters(NSString *string)
{
    if (string == nil) return NO;
    if ([string rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]].location == NSNotFound) return NO;
    return YES;
}

static NSSet *RKScanVariablesFromString(NSString *string)
{
    NSMutableSet *variables = [NSMutableSet set];
    for (NSString *component in [string componentsSeparatedByString:@"/"]) {
        BOOL parsedVariableForComponent = NO;
        NSScanner *scanner = [NSScanner scannerWithString:component];
        [scanner setCharactersToBeSkipped:nil]; // NSScanner skips whitespace by default

        while (![scanner isAtEnd]) {
            NSString *variable = nil;
            [scanner scanUpToString:@"{" intoString:&variable];
            NSUInteger index = ([scanner isAtEnd] ? [scanner scanLocation] - 1 : [scanner scanLocation]);
            BOOL foundOpeningBrace = ([component characterAtIndex:index] == '{');

            if (foundOpeningBrace) {
                if (![scanner isAtEnd]) [scanner setScanLocation:[scanner scanLocation] + 1];
            } else {
                if (variable && [variable rangeOfString:@"}"].location != NSNotFound) {
                    [NSException raise:NSInvalidArgumentException format:@"Invalid path template: Unopened variable encountered. A '}' character must be preceded by a '{' character."];
                }

                // No opening brace found, there's no variable to parse
                break;
            }

            variable = nil;
            [scanner scanUpToString:@"}" intoString:&variable];
            index = ([scanner isAtEnd] ? [scanner scanLocation] - 1 : [scanner scanLocation]);
            if (variable && ![scanner isAtEnd]) [scanner setScanLocation:[scanner scanLocation] + 1];
            if ([component characterAtIndex:index] == '}') {
                if ([variable length] == 0) { // /{}
                    [NSException raise:NSInvalidArgumentException format:@"Invalid path template: '{}' is not a valid variable specifier."];
                }
                if ([variable rangeOfString:@"{"].length > 0) { // /{variable{whatever}
                    [NSException raise:NSInvalidArgumentException format:@"Invalid path template: Unclosed variable encountered. A '{' character must be followed by a '}' character."];
                }
                if ([variables containsObject:variable]) { // /{variable}/{variable}
                    [NSException raise:NSInvalidArgumentException format:@"Invalid path template: variable names must be unique."];
                }
                if (parsedVariableForComponent) {
                    [NSException raise:NSInvalidArgumentException format:@"Invalid path template: A path component can only contain a single variable specifier."];
                }

                [variables addObject:variable];
                parsedVariableForComponent = YES;
            } else if (foundOpeningBrace) {
                [NSException raise:NSInvalidArgumentException format:@"Invalid path template: Unclosed variable encountered. A '{' character must be followed by a '}' character."];
            }
        }
    }
    return variables;
}

@interface RKPathTemplateComponent : NSObject
@property (nonatomic, strong) NSSet *variables;
- (id)initWithString:(NSString *)string;
- (NSString *)expandWithVariables:(NSDictionary *)variables;
- (BOOL)matchesString:(NSString *)componentString variable:(id)variable;
@property (nonatomic, readwrite) NSString *path;
@end

@implementation RKPathTemplateComponent

- (id)initWithString:(NSString *)string
{
    if (self == [super init]) {
        self.path = string;
        self.variables = RKScanVariablesFromString(string);
    }
    return self;
}

- (NSString *)expandWithVariables:(NSDictionary *)variables
{
    if (variables == nil && [self.variables count]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"variables should not be nil" userInfo:nil];
    }
    
    for (NSString *key in self.variables) {
        NSRange range = [self.path rangeOfString:[NSString stringWithFormat:@"{%@}", key]];
        if (range.location == NSNotFound) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"RKTemplatePath does not contain a variable with name:%@", key] userInfo:nil];
        } else {
            id value = [variables objectForKey:key];
            if (value == nil) {
               @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"`variables` does not contain a value for key: %@", key] userInfo:nil];
            }
            if (value == [NSNull null]) {
                value = @"";
            }
            return [self.path stringByReplacingCharactersInRange:range withString:[NSString stringWithFormat:@"%@", value]];
        }
    }
    return self.path;
}

- (BOOL)matchesString:(NSString *)componentString variable:(id)variable
{
    NSMutableString *expandedPath = [componentString mutableCopy];
    if ([self.variables count]) {
        if (RKStringHasBraceCharacters(componentString)) {
            return [self.path isEqualToString:expandedPath];
        } else {
            return variable != nil;
        }
    } else {
        return [self.path isEqualToString:expandedPath];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p path='%@' variables='%@'>", NSStringFromClass([self class]), self, self.path, self.variables];
}

@end

@interface RKVariablePathTemplateComponent : RKPathTemplateComponent
@end

@implementation RKVariablePathTemplateComponent
@end

@interface RKPathTemplate ()

@property (nonatomic, strong) NSString *pathTemplate;
@property (nonatomic, strong) NSString *patternString;
@property (nonatomic, strong) NSSet *variables;
@property (nonatomic, strong) NSArray *parameters;
@property (nonatomic, strong) NSArray *pathComponents;
@end

@implementation RKPathTemplate

- (BOOL)matchesPath:(NSString *)path variables:(NSDictionary **)variables
{
    NSMutableString *pathToMatch = [path mutableCopy];
    if ([pathToMatch rangeOfString:@"?"].location != NSNotFound) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Path Should Not Contain Query String:%@", [path substringFromIndex:[pathToMatch rangeOfString:@"?"].location]] userInfo:nil];
    }
    // Trailing Slash
    if ([pathToMatch hasSuffix:@"/"]) { // normalize string by appending / if does not contain one
        pathToMatch = [pathToMatch substringToIndex:[pathToMatch length] - 1];
    }
    
    // Leading Slash
    if ([pathToMatch hasPrefix:@"/"]) {
        pathToMatch = [pathToMatch substringFromIndex:1];
    }

    NSMutableArray *pathComponents = [pathToMatch pathComponents];
    if ([pathComponents count] != [self.pathComponents count]) {
        return NO;
    }
    __block BOOL matchesPath = NO;
    NSMutableDictionary *pathVariables = [NSMutableDictionary new];
    [self.pathComponents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        RKPathTemplateComponent *component = (RKPathTemplateComponent *)obj;
        if (RKStringHasBraceCharacters(component.path)) {
            NSString *variable = [component.path substringWithRange:NSMakeRange(1, [component.path length] - 2)];
            [pathVariables setObject:[pathComponents objectAtIndex:idx] forKey:variable];
        }
        matchesPath = [component matchesString:pathToMatch variable:[pathComponents objectAtIndex:idx]];
    }];
    
    if (variables) *variables = [pathVariables copy];

    // Ensure paths with and without leading slashes are different.
    if ([self.pathTemplate hasPrefix:@"/"] && ![path hasPrefix:@"/"]) return NO;
    
    return matchesPath;
}

- (NSString *)expandWithVariables:(NSDictionary *)variables
{
    if (variables == nil) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"variables should not be nil" userInfo:nil];
    if (![self.variables isEqualToSet:[NSSet setWithArray:[variables allKeys]]]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"variables should contains the same number of objects and keys as the RKPathTemplate" userInfo:nil];
    }
    NSMutableString *expandedPath = [NSMutableString new];
    for (RKPathTemplateComponent *component in self.pathComponents) {
        [expandedPath appendString:[NSString stringWithFormat:@"/%@", [component expandWithVariables:variables]]];
    }
    return expandedPath;
}

- (NSUInteger)hash
{
    return [self.pathTemplate hash];
}

- (BOOL)isEqual:(id)object
{
    if (object == nil) return NO;
    if (![object isKindOfClass:[RKPathTemplate class]]) return NO;
    return [self hash] == [object hash];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    RKPathTemplate *copy = [[[self class] allocWithZone:zone] initWithString:self.pathTemplate];
    return copy;
}

#pragma mark - Initialization

- (id)initWithString:(NSString *)string
{
    if ([string length] == 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Path Template String Should Not Be `nil` or Length Zero." userInfo:nil];
    }
    
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Path Template String Should Not Be Composed of All Whitespace." userInfo:nil];
    }

    if (self = [super init]) {
        self.pathTemplate = [string copy];
        NSArray *variables = RKScanVariablesFromString(string);
        if (RKIsValidSetOfVariables(variables)) {
            self.variables = variables;
        }

        NSMutableArray *pathComponents = [NSMutableArray arrayWithCapacity:[[string pathComponents] count]];
        for (NSString *componentString in [string pathComponents]) {
            if ([componentString isEqualToString:@"/"]) continue;
            if (RKStringHasBraceCharacters(string)) {
                [pathComponents addObject:[[RKVariablePathTemplateComponent alloc] initWithString:componentString]];
            } else {
                [pathComponents addObject:[[RKPathTemplateComponent alloc] initWithString:componentString]];
            }
        }
        self.pathComponents = [pathComponents copy];
    }
    return self;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Failed to call the designated initializer. Invoke `pathTemplateWithString:` instead."
                                 userInfo:nil];
}

+ (instancetype)pathTemplateWithString:(NSString *)string
{
    return [[RKPathTemplate alloc] initWithString:string];
}

@end
