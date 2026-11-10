//
//  TBWeatherLayout.m
//  MyOpenWeatherPlus
//

#import "TBWeatherLayout.h"
#import <objc/runtime.h>

static const void *kTBWeatherLayoutDoneKeys = &kTBWeatherLayoutDoneKeys;

void TBWeatherLayoutOnce(UIView *view, NSString *key, dispatch_block_t block) {
    if (!view || !block) {
        return;
    }
    NSString *doneKey = key.length ? key : @"default";
    NSMutableSet<NSString *> *keys = objc_getAssociatedObject(view, kTBWeatherLayoutDoneKeys);
    if (!keys) {
        keys = [NSMutableSet set];
        objc_setAssociatedObject(view, kTBWeatherLayoutDoneKeys, keys, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if ([keys containsObject:doneKey]) {
        return;
    }
    [keys addObject:doneKey];
    block();
}
