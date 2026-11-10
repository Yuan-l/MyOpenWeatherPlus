//
//  QWeatherDayWeatherRowView.m
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//

#import "QWeatherDayWeatherRowView.h"
#import "TBWeatherLayout.h"

#import "CommonMacros.h"
#import "FontAndColorMacros.h"
#import "UtilsMacros.h"
#import <Masonry/Masonry.h>
#import <QMUIKit/QMUIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>

@implementation QWeatherDayWeatherRowView
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configUI];
        self.backgroundColor = QWeatherColor_F0F0F0;
    }
    return self;
}
-(void)configUI{
    self.dayLabel = [QWeatherBaseLabel new];
    [self addSubview:self.dayLabel];
    
    self.dayWeatherImageView = [UIImageView new];
    self.dayWeatherImageView.image = UIImageMake(QWeatherStringFormat(@"todayItem_%d",0));
    [self addSubview:self.dayWeatherImageView];

    self.nightWeatherImageView = [UIImageView new];
    self.nightWeatherImageView.image = UIImageMake(QWeatherStringFormat(@"todayItem_%d",1));
    [self addSubview:self.nightWeatherImageView];
    
    self.maxTempLabel = [QWeatherBaseLabel new];
    self.maxTempLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.maxTempLabel];
    
    self.minTempLabel = [QWeatherBaseLabel new];
    self.minTempLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.minTempLabel];

    UILabel *tempSeparator = [[UILabel alloc] init];
    tempSeparator.text = @"/";
    tempSeparator.tag = 9002;
    tempSeparator.font = [UIFont systemFontOfSize:11];
    tempSeparator.textColor = QWeatherColor_CCCCCC;
    [self addSubview:tempSeparator];

    self.humidityLabel = [QWeatherBaseLabel new];
    self.humidityLabel.hefengFontSize = QWeatherFontSize_12;
    self.humidityLabel.textColor = QWeatherColor_A4A4A4;
    self.humidityLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.humidityLabel];

    UIView *divider = [UIView new];
    divider.backgroundColor = QWeatherColor_ECECEC;
    divider.tag = 9001;
    [self addSubview:divider];
}
-(void)layoutSubviews{
    [super layoutSubviews];
    TBWeatherLayoutOnce(self, @"constraints", ^{
        // 固定列宽，避免温度/湿度文案互相挤压（小屏尤其明显）
        [self.dayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.mas_equalTo(Space_16);
            make.width.mas_equalTo(64);
        }];
        [self.dayWeatherImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self.dayLabel.mas_right).offset(4);
            make.height.width.mas_equalTo(20);
        }];
        [self.nightWeatherImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self.dayWeatherImageView.mas_right).offset(4);
            make.height.width.mas_equalTo(20);
        }];
        [self.humidityLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.right.mas_equalTo(-Space_16);
            make.width.mas_equalTo(56);
        }];
        [self.minTempLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.right.equalTo(self.humidityLabel.mas_left).offset(-8);
            make.width.mas_equalTo(34);
        }];
        UIView *tempSeparator = [self viewWithTag:9002];
        [tempSeparator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.right.equalTo(self.minTempLabel.mas_left).offset(-2);
        }];
        [self.maxTempLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.right.equalTo(tempSeparator.mas_left).offset(-2);
            make.width.mas_equalTo(40);
            make.left.greaterThanOrEqualTo(self.nightWeatherImageView.mas_right).offset(8);
        }];
        UIView *divider = [self viewWithTag:9001];
        [divider mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self);
            make.height.mas_equalTo(0.5);
        }];
    });
}
@end
