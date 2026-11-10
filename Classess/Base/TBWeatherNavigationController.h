//
//  TBWeatherNavigationController.h
//  MyOpenWeatherPlus
//
//  天气模块专用导航控制器：
//  QWeather 的页面依赖 QMUI 的导航栏定制（背景、返回按钮、titleView），
//  必须使用 QMUINavigationController 才能生效，否则城市管理/搜索等二级页
//  会出现「返回按钮字很长、标题位置不对」的问题。
//

#import <QMUIKit/QMUINavigationController.h>

NS_ASSUME_NONNULL_BEGIN

@interface TBWeatherNavigationController : QMUINavigationController

@end

NS_ASSUME_NONNULL_END
