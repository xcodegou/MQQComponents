//
//  NSURLComponents+MQQExtended.m
//  MQQComponents
//
//  Created by klaudz on 24/10/2019.
//

#import "../include/NSURLComponents+MQQExtended.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSURLComponents (MQQExtended)

- (nullable NSArray<NSURLQueryItem *> *)mqqPercentEncodedQueryItems
{
    NSString *query = self.percentEncodedQuery;
    NSArray<NSString *> *queryComponents = [query componentsSeparatedByString:@"&"];;
    if (queryComponents == nil) {
        return nil;
    }
    
    NSMutableArray *queryItems = [NSMutableArray arrayWithCapacity:[queryComponents count]];
    for (NSString *component in queryComponents) {
        NSRange range = [component rangeOfString:@"="];
        if (range.location == NSNotFound) {
            continue;
        }
        NSString *name = [component substringToIndex:range.location];
        NSString *value = [component substringFromIndex:range.location+range.length];
        NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:name value:value];
        [queryItems addObject:queryItem];
    }
    return [NSArray arrayWithArray:queryItems];
}

- (void)setMqqPercentEncodedQueryItems:(nullable NSArray<NSURLQueryItem *> *)queryItems
{
    if (queryItems == nil) {
        self.percentEncodedQuery = nil;
        return;
    }
    
    NSMutableArray<NSString *> *queryComponents = [NSMutableArray array];
    for (NSURLQueryItem *queryItem in queryItems) {
        [queryComponents addObject:[NSString stringWithFormat:@"%@=%@", queryItem.name, queryItem.value ? : @""]];
    }
    NSString *query = [queryComponents componentsJoinedByString:@"&"];
    self.percentEncodedQuery = query;
}

@end

NS_ASSUME_NONNULL_END
