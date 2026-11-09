//
//  QWeatherRequest.m
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//
//  When I wrote this, only God and I understood what I was doing
//  Now, God only knows

#import "QWeatherRequest.h"
#import "QWeatherModel.h"
#import "QWeatherDataManager.h"
#import <QWeather/QWeather.h>

#import "CommonMacros.h"
#import "FontAndColorMacros.h"
#import "UtilsMacros.h"
#import <Masonry/Masonry.h>
#import <QMUIKit/QMUIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>

@implementation QWeatherRequest
-(instancetype)init{
    if (self=[super init]) {
        
        [self getCommands];
    }
    return self;
}

-(void)getCommands{
    _citySearchCommand = [[RACCommand alloc]initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            QWeatherConfigInstance.location = [input objectForKey:@"location"];
            QWeatherConfigInstance.mode= SERCHMODE_TYPE_EXACT;
            QWeatherConfigInstance.languageType= [QWeatherManager isEnglish]?LANGUAGE_TYPE_EN:LANGUAGE_TYPE_ZH;
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_GEO_CITY_LOOKUP WithSuccess:^(GeoBaseClass  *responseObject) {
                [subscriber sendNext:responseObject];
                [subscriber sendCompleted];
            } faileureForError:^(NSError *error) {
                [subscriber sendError:error];
                [subscriber sendCompleted];
            }];
            return nil;
        }];
    }];
    
    _homeDataCommand = [[RACCommand alloc]initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            __block AirBaseClass *AirBaseDataModel;
            __block AirBaseClass *locationAirBaseDataModel;
            __block WarningBaseClass *alarmBaseClass;
            __block Now *now;
            __block NSArray *hourly;
            __block NSArray *daily;
            __block NSString *updateTime;
            __block NSString *code;

            __block NSError *requestError;
            QWeatherConfigInstance.languageType= [QWeatherManager isEnglish]?LANGUAGE_TYPE_EN:LANGUAGE_TYPE_ZH;
            dispatch_group_t group = dispatch_group_create();
            dispatch_group_enter(group);
            QWeatherConfigInstance.location = [input objectForKey:@"cityId"];
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_WEATHER_NOW WithSuccess:^(WeatherBaseClass  *responseObject) {
                now = responseObject.now;
                updateTime = responseObject.updateTime;
                code = responseObject.code;
                dispatch_group_leave(group);
            } faileureForError:^(NSError *err) {
                if (!requestError) { requestError = err; }
                dispatch_group_leave(group);
            }];
            dispatch_group_enter(group);
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_WEATHER_24H WithSuccess:^(WeatherBaseClass  *responseObject) {
                hourly = responseObject.hourly;
                           dispatch_group_leave(group);
                       } faileureForError:^(NSError *err) {
                if (!requestError) { requestError = err; }
                dispatch_group_leave(group);
            }];
            dispatch_group_enter(group);
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_WEATHER_3D WithSuccess:^(WeatherBaseClass  *responseObject) {
                daily = responseObject.daily;
                           dispatch_group_leave(group);
                       } faileureForError:^(NSError *err) {
                if (!requestError) { requestError = err; }
                dispatch_group_leave(group);
            }];
            
            if (QWeatherStrValid([input objectForKey:@"parent_city"])) {
                dispatch_group_enter(group);
                QWeatherConfigInstance.location = [input objectForKey:@"parent_city"];
                QWeatherConfigInstance.languageType= [QWeatherManager isEnglish]?LANGUAGE_TYPE_EN:LANGUAGE_TYPE_ZH;
                [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_WEATHER_AIR_NOW WithSuccess:^(AirBaseClass  *responseObject) {
                    AirBaseDataModel = responseObject;
                    dispatch_group_leave(group);
                } faileureForError:^(NSError *err) {
                if (!requestError) { requestError = err; }
                dispatch_group_leave(group);
            }];
            }
            dispatch_group_enter(group);
            QWeatherConfigInstance.location = [input objectForKey:@"location"];
            QWeatherConfigInstance.languageType= [QWeatherManager isEnglish]?LANGUAGE_TYPE_EN:LANGUAGE_TYPE_ZH;
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_WEATHER_AIR_NOW WithSuccess:^(AirBaseClass  *responseObject) {
                locationAirBaseDataModel = responseObject;
                dispatch_group_leave(group);
            } faileureForError:^(NSError *err) {
                if (!requestError) { requestError = err; }
                dispatch_group_leave(group);
            }];
            //预警
            dispatch_group_enter(group);
            QWeatherConfigInstance.location = [input objectForKey:@"cityId"];
            QWeatherConfigInstance.languageType= [QWeatherManager isEnglish]?LANGUAGE_TYPE_EN:LANGUAGE_TYPE_ZH;
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_WARNING WithSuccess:^(WarningBaseClass  *responseObject) {
                alarmBaseClass = responseObject;
                dispatch_group_leave(group);
            } faileureForError:^(NSError *error) {
                dispatch_group_leave(group);
            }];
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                if (requestError) {
                    [subscriber sendError:requestError];
                    [subscriber sendCompleted];
                }else{
                  
                    QWeatherHomeTabelViewDataModel *model = [QWeatherHomeTabelViewDataModel new];
                    if (QWeatherStrValid(locationAirBaseDataModel.now.pm2p5)) {
                        model.airDataModel = locationAirBaseDataModel;
                    }else if (QWeatherStrValid(AirBaseDataModel.now.pm2p5)){
                        model.airDataModel = AirBaseDataModel;
                    }
                    model.daily = daily;
                    model.hourly = hourly;
                    model.now = now;
                    model.updateTime = updateTime;
                    model.AlarmDataModel = alarmBaseClass;
                    model.code = code;
                    [subscriber sendNext:model];
                    [subscriber sendCompleted];
                }
            });
            return nil;
        }];
    }];
    _upDateHomeDataCommand = [[RACCommand alloc]initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            QWeatherConfigInstance.languageType = [QWeatherManager isEnglish]?LANGUAGE_TYPE_EN:LANGUAGE_TYPE_ZH;

            NSArray<QWeatherHomeTabelViewDataModel *> *cities = [QWeatherManager.collectionDataArray copy];
            if (cities.count == 0) {
                [subscriber sendNext:@[]];
                [subscriber sendCompleted];
                return nil;
            }

            // 和风 SDK 用全局单例承载 location，并发刷新会互相覆盖，这里逐个城市串行请求
            RACSignal *chain = [RACSignal return:@[]];
            for (NSInteger idx = 0; idx < (NSInteger)cities.count; idx++) {
                QWeatherHomeTabelViewDataModel *city = cities[idx];
                NSMutableDictionary *param = [NSMutableDictionary dictionary];
                param[@"cityId"] = city.basic.cid ?: @"";
                param[@"location"] = city.basic.name ?: @"";
                param[@"parent_city"] = city.basic.adm2 ?: @"";

                chain = [chain flattenMap:^RACSignal *(NSArray *results) {
                    RACSignal *one = [[[[QWeatherRequest new] homeDataCommand] execute:param] flattenMap:^RACSignal *(QWeatherHomeTabelViewDataModel *x) {
                        if (!QWeatherStrEqual(x.code, @"200")) {
                            // 单个城市失败时保留旧数据，不影响其它城市刷新
                            return [RACSignal return:[results arrayByAddingObject:city]];
                        }
                        x.basic = city.basic;
                        return [RACSignal return:[results arrayByAddingObject:x]];
                    }];
                    return [one catch:^RACSignal *(NSError *error) {
                        return [RACSignal return:[results arrayByAddingObject:city]];
                    }];
                }];
            }

            [chain subscribeNext:^(NSArray *results) {
                [QWeatherManager updateCollectionDataArrayWithArray:results];
                [subscriber sendNext:results];
            } error:^(NSError *error) {
                [subscriber sendError:error];
                [subscriber sendCompleted];
            } completed:^{
                [subscriber sendCompleted];
            }];
            return nil;
        }];
    }];
    
    
}
@end
