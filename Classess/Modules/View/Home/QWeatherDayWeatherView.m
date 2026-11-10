//
//  QWeatherDayWeatherView.m
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//

#import "QWeatherDayWeatherView.h"
#import "QWeatherDayWeatherRowView.h"
#import "QWeatherTool.h"
#import "QWeatherDataManager.h"

#import "CommonMacros.h"
#import "FontAndColorMacros.h"
#import "UtilsMacros.h"
#import <Masonry/Masonry.h>
#import <QMUIKit/QMUIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface QWeatherDayWeatherView()
@property (nonatomic,strong) NSMutableArray<QWeatherDayWeatherRowView*> *rowViewArray;
@property (nonatomic,assign) BOOL didDistribute;
@end
@implementation QWeatherDayWeatherView
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configUI];
        self.backgroundColor = QWeatherColor_F0F0F0;
    }
    return self;
}
-(void)configUI{
    self.rowViewArray = [NSMutableArray array];
}
-(void)layoutSubviews{
    [super layoutSubviews];
    // 15 天/3 天预报均可能在降级后为空，空数组不能做 Masonry 分布
    if (self.rowViewArray.count == 0 || self.didDistribute) { return; }
    self.didDistribute = YES;
    [self.rowViewArray mas_distributeViewsAlongAxis:MASAxisTypeVertical withFixedSpacing:30 leadSpacing:Space_16 tailSpacing:Space_16];
    [self.rowViewArray mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
    }];
}
-(void)reloadViewWithModel:(QWeatherHomeTabelViewDataModel *)model{
    [self.rowViewArray enumerateObjectsUsingBlock:^(QWeatherDayWeatherRowView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [self.rowViewArray removeAllObjects];
    self.didDistribute = NO;

    //优先展示 15 天数据，若无则回退到 3 天数据
    NSArray<Daily *> *dailyList = model.daily15.count > 0 ? model.daily15 : model.daily;
    [dailyList enumerateObjectsUsingBlock:^(Daily * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        QWeatherDayWeatherRowView *view = [QWeatherDayWeatherRowView new];
        view.dayLabel.hefengFontSize = QWeatherFontSize_14;
        view.dayLabel.textColor = idx==0?QWeatherColor_212121:QWeatherColor_A4A4A4;
        view.maxTempLabel.hefengFontSize = QWeatherFontSize_14;
        view.maxTempLabel.textColor = QWeatherColor_4A4A4A;
        view.minTempLabel.hefengFontSize = QWeatherFontSize_14;
        view.minTempLabel.textColor = QWeatherColor_7A7A7A;
        [self addSubview:view];
        [self.rowViewArray addObject:view];
    }];
    [self.rowViewArray enumerateObjectsUsingBlock:^(QWeatherDayWeatherRowView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.dayLabel.text = QWeatherLocal([QWeatherTool getTimeStringWithSting:dailyList[idx].fxDate dateformat:QWeatherFormatString3 isShowToday:YES]);
        obj.maxTempLabel.hefengTempString = dailyList[idx].tempMax;
        obj.minTempLabel.hefengTempString = dailyList[idx].tempMin;
        obj.humidityLabel.text = [NSString stringWithFormat:@"湿度%@%%", dailyList[idx].humidity];
        obj.dayWeatherImageView.image = [QWeatherTool getWeatherImageWithWeatherCode:dailyList[idx].iconDay isDay:YES formatString:QWeatherImageFormatString];
        obj.nightWeatherImageView.image = [QWeatherTool getWeatherImageWithWeatherCode:dailyList[idx].iconNight isDay:NO formatString:QWeatherImageFormatString];
    }];
    [self setNeedsLayout];
}
@end
