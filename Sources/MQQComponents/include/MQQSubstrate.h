//
//  MQQSubstrate.h
//  MQQSecure
//
//  Created by cererdlong on 12-11-20.
//  Modified by klaudz on 2019-5-25.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

// Hook (Replace)
FOUNDATION_EXTERN
IMP _Nullable _MQQHookMessage(Class aClass, SEL selector, IMP _Nonnull replacedIMP);

template <typename _Type_>
static _Type_ * _Nullable MQQHookMessage(Class aClass, SEL selector, _Type_ * _Nonnull replacedIMP) {
    return reinterpret_cast<_Type_ *>(_MQQHookMessage(aClass, selector, reinterpret_cast<IMP>(replacedIMP)));
}

// Hook (Replace)
FOUNDATION_EXTERN
IMP _Nullable _MQQHookMessageEx(Class aClass, SEL selector, IMP _Nonnull replacedIMP, IMP _Nullable * _Nonnull originalIMP);

template <typename _Type_>
static _Type_ * _Nullable MQQHookMessageEx(Class aClass, SEL selector, _Type_ * _Nonnull replacedIMP, _Type_ * _Nullable * _Nonnull originalIMP) {
    return reinterpret_cast<_Type_ *>(_MQQHookMessageEx(aClass, selector, reinterpret_cast<IMP>(replacedIMP), reinterpret_cast<IMP *>(originalIMP)));
}

// Hook (Replace or Add)
FOUNDATION_EXTERN
IMP _Nullable _MQQHookMessageRA(Class aClass, SEL selector, IMP _Nonnull replacedIMP, const char *types);

template <typename _Type_>
static _Type_ * _Nullable MQQHookMessageRA(Class aClass, SEL selector, _Type_ * _Nonnull replacedIMP, const char *types) {
    return reinterpret_cast<_Type_ *>(_MQQHookMessageRA(aClass, selector, reinterpret_cast<IMP>(replacedIMP), types));
}

#define MQQ_REPLACED(class_name, return_type, method_name, parameters...) \
static return_type (*_ ## class_name ## $ ## method_name)(class_name *self, SEL sel, ## parameters); \
static return_type $ ## class_name ## $ ## method_name(class_name *self, SEL sel, ## parameters)

#define MQQ_ORIGINAL(class_name, method_name, parameters...) \
_ ## class_name ## $ ## method_name(self, sel, ## parameters)

#define MQQ_ORIGINAL_EXISTS(class_name, method_name) \
(_ ## class_name ## $ ## method_name != NULL)

#define MQQ_HOOK(class_name, method_name, class, selector) \
_ ## class_name ## $ ## method_name = MQQHookMessage(class, selector, &$ ## class_name ## $ ## method_name);

#define MQQ_HOOK_EX(class_name, method_name, class, selector, types) \
_ ## class_name ## $ ## method_name = MQQHookMessageRA(class, selector, &$ ## class_name ## $ ## method_name, types);

NS_ASSUME_NONNULL_END
