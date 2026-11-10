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

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // 天气二级页统一用「箭头」返回按钮，避免默认的「返回」文字把标题挤偏
    if (@available(iOS 14.0, *)) {
        viewController.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;
    } else {
        self.topViewController.navigationItem.backBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    [super pushViewController:viewController animated:animated];
}

@end
