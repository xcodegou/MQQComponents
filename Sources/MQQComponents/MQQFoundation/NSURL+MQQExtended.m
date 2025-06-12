//
//  NSURL+MQQExtended.m
//  MQQSecure
//
//  Created by klaudz on 4/16/15.
//  Copyright (c) 2015 Tencent. All rights reserved.
//

#import "../include/NSURL+MQQExtended.h"
#import "../include/NSURLComponents+MQQExtended.h"

@implementation NSURL (MQQExtended)

- (NSArray<NSString *> *)mqqQueryComponents
{
    NSString *query = [self query];
    if (query) {
        return [query componentsSeparatedByString:@"&"];
    }
    return nil;
}

- (NSDictionary<NSString *, NSString *> *)mqqQueryDictionary
{
    NSArray *queryComponents = [self mqqQueryComponents];
    if (queryComponents) {
        NSMutableDictionary *queryDictionary = [NSMutableDictionary dictionaryWithCapacity:[queryComponents count]];
        for (NSString *component in queryComponents) {
            NSRange range = [component rangeOfString:@"="];
            if (range.location == NSNotFound) {
                continue;
            }
            NSString *key = [component substringToIndex:range.location];
            NSString *value = [component substringFromIndex:range.location+range.length];
            [queryDictionary setObject:value forKey:key];
        }
        return [NSDictionary dictionaryWithDictionary:queryDictionary];
    }
    return nil;
}

- (NSURL *)mqqURLByAppendingQuery:(NSString *)query
{
    NSArray<NSString *> *queryComponents = [query componentsSeparatedByString:@"&"];
    return [self mqqURLByAppendingQueryComponents:queryComponents];
}

- (NSURL *)mqqURLByAppendingQueryComponents:(NSArray<NSString *> *)queryComponents
{
    NSMutableDictionary *queryComponentDictionary = [NSMutableDictionary dictionaryWithCapacity:queryComponents.count];
    for (NSString *queryItemString in queryComponents) {
        NSUInteger index = [queryItemString rangeOfString:@"="].location;
        if (index == NSNotFound) {
            continue;
        }
        NSString *name = [queryItemString substringToIndex:index];
        NSString *value = [queryItemString substringFromIndex:index + 1];
        [queryComponentDictionary setObject:value forKey:name];
    }
    return [self mqqURLByAppendingQueryComponentDictionary:queryComponentDictionary];
}

- (NSURL *)mqqURLByAppendingQueryComponentDictionary:(NSDictionary<NSString *, NSString *> *)queryComponentDictionary
{
    if ([queryComponentDictionary count] == 0) {
        return self;
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    NSArray<NSURLQueryItem *> *oldQueryItems = components.mqqPercentEncodedQueryItems;
    NSMutableArray<NSURLQueryItem *> *newQueryItems = [NSMutableArray arrayWithCapacity:oldQueryItems.count + queryComponentDictionary.count];
    for (NSURLQueryItem *item in oldQueryItems) {
        [newQueryItems addObject:item];
    }
    for (NSString *name in queryComponentDictionary) {
        NSString *value = [queryComponentDictionary objectForKey:name];
        NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:name value:value];
        [newQueryItems addObject:item];
    }
    components.mqqPercentEncodedQueryItems = newQueryItems;
    return components.URL;
}

- (NSURL *)mqqURLByDeletingQueryNames:(NSArray<NSString *> *)queryNames
{
    if ([queryNames count] == 0) {
        return self;
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    NSArray<NSURLQueryItem *> *oldQueryItems = components.mqqPercentEncodedQueryItems;
    NSMutableArray<NSURLQueryItem *> *newQueryItems = [NSMutableArray arrayWithCapacity:oldQueryItems.count];
    for (NSURLQueryItem *item in oldQueryItems) {
        if ([queryNames containsObject:item.name]) {
            continue;
        }
        [newQueryItems addObject:item];
    }
    components.mqqPercentEncodedQueryItems = newQueryItems;
    return components.URL;
}

@end
