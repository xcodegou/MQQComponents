//
//  MQQSubstrate.c
//  MQQSecure
//
//  Created by cererdlong on 12-11-20.
//  Modified by klaudz on 2019-5-25.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//

#import "../include/MQQSubstrate.h"
#include <stdio.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN
IMP _Nullable _MQQHookMessage(Class aClass, SEL selector, IMP _Nonnull replacedIMP) {
    Method method = class_getInstanceMethod(aClass, selector);
    IMP originalIMP = method_setImplementation(method, replacedIMP);
    return originalIMP;
}

FOUNDATION_EXTERN
IMP _Nullable _MQQHookMessageEx(Class aClass, SEL selector, IMP _Nonnull replacedIMP, IMP * _Nonnull originalIMP) {
    Method method = class_getInstanceMethod(aClass, selector);
    *originalIMP = method_setImplementation(method, replacedIMP);
    return *originalIMP;
}

FOUNDATION_EXTERN
IMP _Nullable _MQQHookMessageRA(Class aClass, SEL selector, IMP _Nonnull replacedIMP, const char *types) {
    Method method = class_getInstanceMethod(aClass, selector);
    if (method) {
        IMP originalIMP = method_setImplementation(method, replacedIMP);
        return originalIMP;
    } else {
        class_addMethod(aClass, selector, replacedIMP, types);
    }
    return NULL;
}

NS_ASSUME_NONNULL_END
