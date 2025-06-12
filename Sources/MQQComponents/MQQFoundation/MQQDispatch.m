//
//  MQQDispatch.m
//  MQQSecure
//
//  Created by klaudz on 5/6/15.
//  Copyright (c) 2015 Tencent. All rights reserved.
//

#import "../include/MQQDispatch.h"

void mqq_dispatch_to_queue(dispatch_queue_t queue, const void *key, dispatch_block_t block)
{
    // if (dispatch_get_current_queue() == queue) {
    if (dispatch_get_specific(key) != NULL) {
        block();
    } else {
        dispatch_async(queue, block);
    }
}


void mqq_dispatch_to_main_queue(dispatch_block_t block)
{
#ifdef TMF_MESS_TEMP_LICENSE_CHECK_POINT
    TMF_MESS_TEMP_LICENSE_CHECK_POINT
#endif
    
    // __mqq_dispatch_to_queue(dispatch_get_main_queue(), block);
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}


void mqq_dispatch_sync_to_queue(dispatch_queue_t queue, const void *key, dispatch_block_t block)
{
    // if (dispatch_get_current_queue() == queue) {
    if (dispatch_get_specific(key) != NULL) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}


void mqq_dispatch_sync_to_main_queue(dispatch_block_t block)
{
#ifdef TMF_MESS_TEMP_LICENSE_CHECK_POINT
    TMF_MESS_TEMP_LICENSE_CHECK_POINT
#endif
    
    // __mqq_dispatch_sync_to_queue(dispatch_get_main_queue(), block);
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

