//
//  TBWeatherNavigationController.m
//  MyOpenWeatherPlus
//

#import "TBWeatherNavigationController.h"

@implementation TBWeatherNavigationController

- (void)didInitialize {
    [super didInitialize];
    self.navigationBar.translucent = NO;
    // 统一返回箭头：只保留图标，不带上一页标题
    if (@available(iOS 13.0, *)) {
        UIImage *chevron = [UIImage systemImageNamed:@"chevron.left"
                                   withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:16
                                                                                                      weight:UIImageSymbolWeightSemibold]];
        self.navigationBar.backIndicatorImage = chevron;
        self.navigationBar.backIndicatorTransitionMaskImage = chevron;
    }
}

@end
