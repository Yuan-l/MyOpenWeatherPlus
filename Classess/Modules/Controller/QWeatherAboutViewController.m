//
//  QWeatherAboutViewController.m
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//

#import "QWeatherAboutViewController.h"
#import "QWeatherBaseLabel.h"
#import "QWeatherDataManager.h"

#import "CommonMacros.h"
#import "FontAndColorMacros.h"
#import "UtilsMacros.h"
#import <Masonry/Masonry.h>
#import <QMUIKit/QMUIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface QWeatherAboutViewController ()
@property (nonatomic,strong) UIImageView *iconImageView;
@property (nonatomic,strong) QWeatherBaseLabel *titleLabel;
@end

@implementation QWeatherAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleView.title = QWeatherLocal(@"hengfengLocalString_25");
    [self configUI];
}
-(void)configUI{
    self.iconImageView = [UIImageView new];
    self.iconImageView.image = UIImageMake(@"hefeng_about");
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    kViewRadius(self.iconImageView, 10);
    [self.view addSubview:self.iconImageView];
    
    self.titleLabel = [QWeatherBaseLabel new];
    self.titleLabel.hefengLocalString = @"hengfengLocalString_27";
    self.titleLabel.hefengFontSize = QWeatherFontSize_17;
    self.titleLabel.textColor = QWeatherColor_212121;
    [self.view addSubview:self.titleLabel];
    
    UIView *rowView = [UIView new];
    rowView.backgroundColor = QWeatherColor_FAFAFA;
    [self.view addSubview:rowView];
    
    QWeatherBaseLabel *currentVersionLabel = [QWeatherBaseLabel new];
    currentVersionLabel.hefengLocalString = @"hengfengLocalString_26";
    currentVersionLabel.hefengFontSize = QWeatherFontSize_14;
    currentVersionLabel.textColor = QWeatherColor_4A4A4A;
    [rowView addSubview:currentVersionLabel];
    
    QWeatherBaseLabel *currentVersionNmuberLabel = [QWeatherBaseLabel new];
    currentVersionNmuberLabel.text =APP_VERSION;
    currentVersionNmuberLabel.hefengFontSize = QWeatherFontSize_14;
    currentVersionNmuberLabel.textColor = QWeatherColor_A4A4A4;
    [rowView addSubview:currentVersionNmuberLabel];
    
    
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(0);
        make.top.equalTo(self.mas_topLayoutGuide).offset(78);
        make.width.height.mas_equalTo(88);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(0);
        make.top.equalTo(self.iconImageView.mas_bottom).offset(17);
    }];
    
    [rowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(0);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(50);
        make.height.mas_equalTo(50);
    }];
    [currentVersionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(Space_16);
        make.centerY.equalTo(0);
    }];
    [currentVersionNmuberLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-Space_16);
        make.centerY.equalTo(0);
    }];
}

@end
