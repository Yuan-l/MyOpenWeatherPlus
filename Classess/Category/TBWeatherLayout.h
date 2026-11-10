//
//  TBWeatherLayout.h
//  MyOpenWeatherPlus
//
//  布局工具：避免在 layoutSubviews 中重复添加 Masonry 约束
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 在 layoutSubviews 中调用，block 只会执行一次（首次布局）。
/// 原代码把 mas_makeConstraints 写在 layoutSubviews 里，每次布局都会叠加一组新约束，
/// 造成约束爆炸、温度等文案错位，这里统一收敛为一次。
/// @param key 同一 view 上的多个约束块需要不同的 key，否则只有第一个会执行
FOUNDATION_EXPORT void TBWeatherLayoutOnce(UIView *view, NSString *key, dispatch_block_t block);

NS_ASSUME_NONNULL_END
