//
//  TBWeatherCityBar.h
//  MyOpenWeatherPlus
//
//  天气首页城市切换条：横向滚动的城市 chips + 添加城市入口。
//  解决「不知道点哪里切换城市」的问题，城市列表始终可见。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TBWeatherCityBar : UIView

/// 选中城市回调
@property (nonatomic, copy) void (^onSelect)(NSInteger index);
/// 点击「＋」添加城市
@property (nonatomic, copy) void (^onAdd)(void);
/// 长按城市 chip 进入城市管理（排序/删除）
@property (nonatomic, copy) void (^onManage)(void);

/// 用城市名重建 chips，并高亮 selectedIndex
- (void)reloadWithCityNames:(NSArray<NSString *> *)names selectedIndex:(NSInteger)selectedIndex;

/// 仅更新高亮（滑动翻页时调用）
- (void)updateSelectedIndex:(NSInteger)selectedIndex;

@end

NS_ASSUME_NONNULL_END
