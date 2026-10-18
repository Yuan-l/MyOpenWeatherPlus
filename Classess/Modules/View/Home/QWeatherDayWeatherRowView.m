//
//  QWeatherDayWeatherRowView.m
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//

#import "QWeatherDayWeatherRowView.h"

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
    [self addSubview:self.maxTempLabel];
    
    self.minTempLabel = [QWeatherBaseLabel new];
    self.minTempLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.minTempLabel];
}
-(void)layoutSubviews{
    [super layoutSubviews];
    [self.dayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(0);
        make.left.mas_equalTo(Space_16);
    }];
    [self.dayWeatherImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(0);
        make.right.equalTo(self.mas_centerX).offset(-Space_16);
        make.height.width.mas_equalTo(20);
    }];
    [self.nightWeatherImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(0);
        make.left.equalTo(self.mas_centerX).offset(Space_16);
        make.height.width.mas_equalTo(20);
    }];
    [self.minTempLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self);
        make.right.mas_equalTo(-Space_16);
    }];
    [self.maxTempLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self);
        make.right.equalTo(self.minTempLabel.mas_left).offset(-Space_16);
    }];
}
@end
