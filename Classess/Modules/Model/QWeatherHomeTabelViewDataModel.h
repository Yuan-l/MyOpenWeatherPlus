//
//  QWeatherHomeTabelViewDataModel.h
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//
//  When I wrote this, only God and I understood what I was doing
//  Now, God only knows

#import "QWeatherModel.h"
//#import <MyOpenWeatherPlus/QWeather.h>
#import <QWeather/QWeather.h>

NS_ASSUME_NONNULL_BEGIN
//@class AirBaseClass;
//@class Location;
//@class Now;
//@class Hourly;
//@class Daily;

@interface QWeatherHomeTabelViewDataModel : QWeatherModel
/**
 实况天气
 */
@property (nonatomic,strong) Now *now;
/**
逐小时天气
*/
@property (nonatomic,strong) NSArray< Hourly *> *hourly;
/**
逐天天气
*/
@property (nonatomic,strong) NSArray< Daily*> *daily;
/**
 15天逐日天气（含 sunrise/sunset/uvIndex/humidity/windDirDay 等）
 */
@property (nonatomic,strong) NSArray< Daily*> *daily15;
/**
 生活指数数据模型（穿衣/紫外线/洗车/运动/舒适度/感冒）
 */
@property (nonatomic,strong) IndicesBaseClass *indicesModel;
/**
 日月数据模型（日出日落/月出月落/月相）
 */
@property (nonatomic,strong) SunMoonBaseModel *sunMoonModel;

/**
 空气数据模型
 */
@property (nonatomic,strong) AirBaseClass *airDataModel;
/**
 预警数据模型
 */
@property (nonatomic,strong) WarningBaseClass *AlarmDataModel;
/**
 Location数据模型
*/
@property (nonatomic,strong) Location *basic;

@property (nonatomic,copy) NSString *updateTime;

@property (nonatomic,copy) NSString *code;

@end

NS_ASSUME_NONNULL_END
