//
//  RKParameterConstraint.m
//  RestKit
//
//  Created by Kurry Tran on 12/8/13.
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

#import "RKParameterConstraint.h"

NSString *const RKParameterConstraintErrorDomain  = @"org.restkit.RestKit.RKParameterConstraint.ErrorDomain";
NSString *const RKOptionalParametersKey = @"RKOptionalParametersKey";
NSString *const RKRequiredParametersKey = @"RKRequiredParametersKey";

@interface RKConstraintsValidator : NSObject
+ (BOOL)isValidParameter:(NSString *)parameter  error:(NSError **)error;
+ (BOOL)isValidValue:(id)value  error:(NSError **)error;
+ (BOOL)isValidDictionaryOfParameterConstraints:(NSDictionary *)constraints error:(NSError **)error;
+ (BOOL)validateParameter:(NSString *)parameter value:(id)value  error:(NSError **)error;
@end

@implementation RKConstraintsValidator

+ (BOOL)isValidParameter:(NSString *)parameter  error:(NSError **)error
{
    NSString *errorDescription;
    if ([parameter length] == 0) {
        errorDescription = @"parameter string should not be `nil` or length zero.";
        if (error) {
            *error = [NSError errorWithDomain:RKParameterConstraintErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : errorDescription}];
        }
        return NO;
    }
    
    if ([[parameter stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        errorDescription = @"parameter string should not be composed of all whitespace.";
        if (error) {
            *error = [NSError errorWithDomain:RKParameterConstraintErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : errorDescription}];
        }
        return NO;
    }
    
    return YES;
}

+ (BOOL)isValidValue:(id)value  error:(NSError **)error
{
    NSString *errorDescription;
    if (value == nil) {
        errorDescription = @"`value` should not be nil";
        if (error) {
            *error = [NSError errorWithDomain:RKParameterConstraintErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : errorDescription}];
        }
        return NO;
    }
    
    if (![value isKindOfClass:[NSString class]] && ![value isKindOfClass:[NSArray class]] && ![value isKindOfClass:[NSSet class]] && ![value isKindOfClass:[NSRegularExpression class]]) {
        errorDescription = [NSString stringWithFormat:@"Value Should Only Be of Class: [ %@, %@, %@]", NSStringFromClass([NSString class]), NSStringFromClass([NSArray class]), NSStringFromClass([NSSet class])];
        if (error) {
            *error = [NSError errorWithDomain:RKParameterConstraintErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : errorDescription}];
        }
        return NO;
    }
    
    if ([value isKindOfClass:[NSString class]]) {
        if ([(NSString *)value length] == 0){
            errorDescription = @"`value` string should not be length zero";
            if (error) {
                *error = [NSError errorWithDomain:RKParameterConstraintErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : errorDescription}];
            }
            return NO;
        }else {
            return YES;
        }
    }
    
    if ([value isKindOfClass:[NSRegularExpression class]]) {
        if ([[(NSRegularExpression *)value pattern] length] == 0 ) {
            errorDescription = @"NSRegularExpression should not have a length zero pattern.";
            if (error) {
                *error = [NSError errorWithDomain:RKParameterConstraintErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : errorDescription}];
            }
            return NO;
        } else {
            return YES;
        }
    }
    
    if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSSet class]]) {
        __block NSInteger foundIndex = NSNotFound;
        __block id invalidValue = nil;
        
        NSArray *values = nil;
        if ([value isKindOfClass:[NSSet class]]) {
            values = [(NSSet *)value allObjects];
        } else {
            values = (NSArray *)value;
        }
        if ([values count] == 0) {
            errorDescription = @"Collections of possible values should not be empty.";
            if (error) {
                *error = [NSError errorWithDomain:RKParameterConstraintErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : errorDescription}];
            }
            return NO;
        }
        [values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (![obj isKindOfClass:[NSString class]]) {
                foundIndex = idx;
                invalidValue = obj;
                *stop = YES;
            }
        }];
        
        if (foundIndex != NSNotFound) {
            errorDescription = [NSString stringWithFormat:@"Parameter values should only be of class NSString and not from class:%@", NSStringFromClass([invalidValue class])];
            if (error) {
                *error = [NSError errorWithDomain:RKParameterConstraintErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : errorDescription}];
            }
            return NO;
        } else {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)isValidDictionaryOfParameterConstraints:(NSDictionary *)constraints error:(NSError **)error
{
    if (constraints == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"constraints should not be nil" userInfo:nil];
    }
    if ([constraints count] == 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"constraints should contain at least one entry" userInfo:nil];
    }
    for (NSString *parameter in [constraints allKeys]) {
        id value = [constraints objectForKey:parameter];
        if (![self validateParameter:parameter value:value error:&error]) return NO;
    }
    return YES;
}

+ (BOOL)validateParameter:(NSString *)parameter value:(id)value  error:(NSError **)error
{
    NSError *parameterError;
    NSError *valueError;
    BOOL validParameter = [self isValidParameter:parameter error:&parameterError];
    BOOL validValue = [self isValidValue:value error:&valueError];
    if (error && !validParameter) {
        *error = [NSError errorWithDomain:RKParameterConstraintErrorDomain code:0 userInfo:parameterError.userInfo];
        return NO;
    }
    if (error && !validValue) {
        *error = [NSError errorWithDomain:RKParameterConstraintErrorDomain code:0 userInfo:valueError.userInfo];
        return NO;
    }
    return YES;
}

+ (BOOL)containsAllStrings:(NSArray *)keys
{
    for (id object in keys) {
        if (![object isKindOfClass:[NSString class]]) return NO;
    }
    return YES;
}

@end

@interface RKExactParameterConstraint : RKParameterConstraint <NSCopying, NSCoding>
@property (nonatomic, strong) NSSet *acceptableValues;
@end

@interface RKRegularExpressionParameterConstraint : RKParameterConstraint <NSCopying, NSCoding>
@property (nonatomic, strong) NSRegularExpression *regularExpression;
@end

@interface RKParameterConstraint ()
@property (nonatomic, strong) NSDictionary *constraints;
@property (nonatomic, copy, readwrite) NSString *parameter;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSSet *acceptableValues;
@property (nonatomic, strong) NSArray *requiredParameters;
@end

@implementation RKParameterConstraint

+ (instancetype)constraintWithParameter:(NSString *)parameter value:(id)value
{
    if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSSet class]]) {
        return [[RKExactParameterConstraint alloc] initWithParameter:parameter value:value];
    }else if ([value isKindOfClass:[NSRegularExpression class]]) {
        return [[RKRegularExpressionParameterConstraint alloc] initWithParameter:parameter value:value];
    }else {
        return [[RKParameterConstraint alloc] initWithParameter:parameter value:value];
    }
}

+ (NSArray *)constraintsWithDictionary:(NSDictionary *)constraintsDictionary
{
    if (constraintsDictionary == nil) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"constraintsDictionary should not be nil" userInfo:nil];
    if ([constraintsDictionary allKeys].count == 0) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"constraintsDictionary should contains at least one entry" userInfo:nil];
    NSMutableArray *constraints = [NSMutableArray new];
    NSMutableDictionary *dictionary = [constraintsDictionary mutableCopy];
    NSArray *optionalParameters = [dictionary objectForKey:RKOptionalParametersKey];
    [dictionary removeObjectForKey:RKOptionalParametersKey];
    NSArray *requiredParameters = [dictionary objectForKey:RKRequiredParametersKey];
    [dictionary removeObjectForKey:RKRequiredParametersKey];

    if ([requiredParameters count] > 0 && ![RKConstraintsValidator containsAllStrings:requiredParameters]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"required parameters should contain an array of strings" userInfo:nil];
    }
    
    if ([optionalParameters count] > 0 && ![RKConstraintsValidator containsAllStrings:optionalParameters]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"optional parameters should contain an array of strings" userInfo:nil];
    }

    NSMutableArray *allKeys = [[dictionary allKeys] mutableCopy];
    [allKeys sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    for (NSString *key in allKeys) {
        id value = [dictionary objectForKey:key];
        NSError *error;
        BOOL validParameter = [RKConstraintsValidator isValidParameter:key error:&error];
        if (!validParameter) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[error.userInfo objectForKey:NSLocalizedDescriptionKey]
                                         userInfo:nil];
        }
        BOOL validValue = [RKConstraintsValidator isValidValue:value error:&error];
        if (!validValue) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[error.userInfo objectForKey:NSLocalizedDescriptionKey]
                                         userInfo:nil];
        }
        if (validParameter && validValue) {
            RKParameterConstraint *constraint = [RKParameterConstraint constraintWithParameter:key value:value];
            if ([optionalParameters containsObject:key]) constraint.optional = YES;
            if ([requiredParameters count] > 0) constraint.requiredParameters = requiredParameters;
            [constraints addObject:constraint];
        }
    }
    
    return constraints;
}

+ (BOOL)areConstraints:(NSArray *)constraints satisfiedByParameters:(NSDictionary *)parameters
{
    if (constraints == nil) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"constraints should not be nil" userInfo:nil];
    if (parameters == nil) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"parameters should not be nil" userInfo:nil];
    
    for (RKParameterConstraint *constraint in constraints) {
        if (![constraint satisfiedByParameters:parameters]) return NO;
    }
    
    return YES;
}

- (BOOL)satisfiedByParameters:(NSDictionary *)parameters
{
    if (parameters == nil) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"parameters should not be nil" userInfo:nil];
    
    if ([parameters objectForKey:self.parameter] == nil && !self.optional) {
        return NO;
    }else if(self.optional && [parameters objectForKey:self.parameter] == nil) {
        return YES;
    }else if ([self.requiredParameters count] > 0) {
        NSSet *requiredSet = [NSSet setWithArray:self.requiredParameters];
        if (![requiredSet isSubsetOfSet:[NSSet setWithArray:[parameters allKeys]]]) return NO;
    }
    
    id constraint = [self.constraints objectForKey:self.parameter];
    id value = [parameters objectForKey:self.parameter];
    
    if (value == nil) {
        return NO;
    }
    
    NSError *error;
    if (![RKConstraintsValidator isValidValue:value error:&error]) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[error.userInfo objectForKey:NSLocalizedDescriptionKey] userInfo:nil];
    
    if ([constraint isKindOfClass:[NSString class]]) {
        if ([constraint isEqualToString:value]) return YES;
    }else if ([constraint isKindOfClass:[NSArray class]] || [constraint isKindOfClass:[NSSet class]]) {
        if ([constraint containsObject:value]) return YES;
    }
    
    return NO;
}

- (id)initWithParameter:(NSString *)parameter value:(id)value
{
    NSError *error;
    if (![RKConstraintsValidator validateParameter:parameter value:value error:&error]) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[error.userInfo objectForKey:NSLocalizedDescriptionKey] userInfo:nil];
    if (self = [super init]) {
        self.parameter = parameter;
        self.value = value;
        self.constraints = @{ parameter : value };
    }
    return self;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Failed to call the designated initializer. Invoke `constraintWithParameter:value:` instead."
                                 userInfo:nil];
}

- (NSUInteger)hash
{
    NSUInteger hash = [self.parameter hash];
    hash = hash * 31u + self.optional;
    hash = hash * 31u + [self.constraints hash];
    hash = hash * 31u + [self.value hash];
    hash = hash * 31u + [self.acceptableValues hash];
    hash = hash * 31u + [self.requiredParameters hash];
    return hash;
}

- (BOOL)isEqual:(id)object
{
    if (object == nil) return NO;
    if (![object isKindOfClass:[RKParameterConstraint class]]) return NO;
    return [self hash] == [object hash];
}

#pragma mark -
#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return [RKParameterConstraint constraintWithParameter:self.parameter value:self.value];
}

#pragma mark -
#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSString *parameter = [aDecoder decodeObjectForKey:@"parameter"];
    id value = [aDecoder decodeObjectForKey:@"value"];
    if ([self initWithParameter:parameter value:value]) {
        self.constraints = [aDecoder decodeObjectForKey:@"constraints"];
        self.parameter = parameter;
        self.optional = [(NSNumber *)[aDecoder decodeObjectForKey:@"optional"] boolValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.constraints forKey:@"constraints"];
    [aCoder encodeObject:self.parameter forKey:@"parameter"];
    [aCoder encodeObject:[NSNumber numberWithBool:self.optional] forKey:@"optional"];
    [aCoder encodeObject:self.value forKey:@"value"];
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"parameter=%@", self.parameter];
    [description appendFormat:@", optional=%d", self.optional];
    [description appendFormat:@", constraints=%@", self.constraints];
    [description appendFormat:@", value=%@", self.value];
    [description appendFormat:@", acceptableValues=%@", self.acceptableValues];
    [description appendString:@">"];
    return description;
}

@end

@implementation RKExactParameterConstraint : RKParameterConstraint

- (id)initWithParameter:(NSString *)parameter value:(id)value
{
    if (self = [super initWithParameter:parameter value:value]) {
        if ([value isKindOfClass:[NSArray class]]) {
            self.acceptableValues = [NSSet setWithArray:value];
        } else if ([value isKindOfClass:[NSSet class]]) {
            self.acceptableValues = (NSSet *)value;
        }
    }
    return self;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) return YES;
    if (!other || ![[other class] isEqual:[self class]]) return NO;
    return [self isEqualToConstraint:other];
}

- (BOOL)isEqualToConstraint:(RKExactParameterConstraint *)constraint
{
    if (self == constraint) return YES;
    if (constraint == nil) return NO;
    if (![super isEqual:constraint]) return NO;
    if (self.acceptableValues != constraint.acceptableValues && ![self.acceptableValues isEqualToSet:constraint.acceptableValues]) return NO;
    return YES;
}

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31u + [self.acceptableValues hash];
    return hash;
}

#pragma mark -
#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    RKExactParameterConstraint *copy = (RKExactParameterConstraint *) [super copyWithZone:zone];
    if (copy != nil) {
        copy.acceptableValues = self.acceptableValues;
    }
    return copy;
}

#pragma mark -
#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.acceptableValues = [coder decodeObjectForKey:@"acceptableValues"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:self.acceptableValues forKey:@"acceptableValues"];
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"acceptableValues=%@", self.acceptableValues];
    [description appendString:@">"];
    return description;
}

@end

@implementation RKRegularExpressionParameterConstraint : RKParameterConstraint

+ (instancetype)constraintWithParameter:(NSString *)parameter value:(id)value
{
    if (![value isKindOfClass:[NSRegularExpression class]]) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"value should be an NSRegularExpression with a non-zero length pattern" userInfo:nil];
    return [[self alloc] initWithParameter:parameter value:value];
}

- (id)initWithParameter:(NSString *)parameter value:(id)value
{
    if (self = [super initWithParameter:parameter value:value]) {
        self.regularExpression = (NSRegularExpression *)value;
    }
    return self;
}

- (BOOL)satisfiedByParameters:(NSDictionary *)parameters
{
    if (parameters == nil) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"parameters should not be nil" userInfo:nil];
    
    if ([parameters objectForKey:self.parameter] == nil && !self.optional) {
        return NO;
    }else if(self.optional && [parameters objectForKey:self.parameter] == nil) {
        return YES;
    }else if ([self.requiredParameters count] > 0) {
        NSSet *requiredSet = [NSSet setWithArray:self.requiredParameters];
        if (![requiredSet isSubsetOfSet:[NSSet setWithArray:[parameters allKeys]]]) return NO;
    }
    
    id value = [parameters objectForKey:self.parameter];
    if (value == nil) {
        return NO;
    }
    
    if (![RKConstraintsValidator isValidValue:value error:nil]) return NO;
    NSString *string = (NSString *)value;
    if ([self.regularExpression rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, [string length])].location != NSNotFound) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) return YES;
    if (!other || ![[other class] isEqual:[self class]]) return NO;
    return [self isEqualToConstraint:other];
}

- (BOOL)isEqualToConstraint:(RKRegularExpressionParameterConstraint *)constraint
{
    if (self == constraint) return YES;
    if (constraint == nil) return NO;
    if (![super isEqual:constraint]) return NO;
    if (self.regularExpression != constraint.regularExpression && ![self.regularExpression isEqual:constraint.regularExpression]) return NO;
    return YES;
}

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31u + [self.regularExpression hash];
    return hash;
}

#pragma mark -
#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    RKRegularExpressionParameterConstraint *copy = (RKRegularExpressionParameterConstraint *) [super copyWithZone:zone];
    if (copy != nil) {
        copy.regularExpression = [self.regularExpression copy];
    }
    return copy;
}

#pragma mark -
#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.regularExpression = [coder decodeObjectForKey:@"regularExpression"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:self.regularExpression forKey:@"regularExpression"];
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"regularExpression=%@", self.regularExpression];
    [description appendString:@">"];
    return description;
}

@end
