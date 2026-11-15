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
#import <TBNetworkManager/TBRequestManager.h>

/// 和风 SDK 是二进制产物、自建 NSURLSession：业务换不了它的传输实现，
/// 所以拿不到 `URLSessionTaskMetrics`（DNS / TCP / TLS / TTFB 一律没有）。
/// 但「发起了哪个接口、耗时多久、成功还是失败」在调用**前后**完全可观测。
/// 这里在调用前记起点，在 success / failure 回调里补一条边界样本，
/// 让天气 tab 也能进统一的网络质量报表，而不是整块声明「不采」。
///
/// URL 用 `sdk://` 逻辑标识，不伪造真实域名（真实域名在 SDK 内部，业务看不到）；
/// 后端按 `endpoint` 聚合，不按 URL 匹配。
static NSString *TBWeatherSDKURL(NSString *endpoint) {
    return [@"sdk://qweather/" stringByAppendingString:endpoint];
}

static void TBWeatherFinish(NSString *endpoint, NSDate *startedAt, NSError *error) {
    NSTimeInterval durationMs = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0;
    [TBBusinessMonitor recordExternalRequest:endpoint
                                          url:TBWeatherSDKURL(endpoint)
                                       status:error ? 0 : 200
                                   durationMs:durationMs
                                        error:error];
}

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
            NSString *keyword = [input objectForKey:@"location"] ?: @"";
            QWeatherConfigInstance.location = keyword;
            // GEO 只作为「本地城市库查不到」时的补充（例如海外城市），
            // 因此用模糊搜索；只用 EXACT 时输入「广」「深」「bei」几乎总是空结果。
            QWeatherConfigInstance.mode = SERCHMODE_TYPE_FUZZY;
            // 中文关键词用中文检索，纯英文/拼音用英文检索，避免命中率为 0
            BOOL hasChinese = [keyword rangeOfString:@"[\\u4e00-\\u9fa5]"
                                             options:NSRegularExpressionSearch].location != NSNotFound;
            QWeatherConfigInstance.languageType = hasChinese ? LANGUAGE_TYPE_ZH : LANGUAGE_TYPE_EN;
            NSDate *geoStartedAt = [NSDate date];
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_GEO_CITY_LOOKUP WithSuccess:^(GeoBaseClass  *responseObject) {
                TBWeatherFinish(@"weather.geo.city_lookup", geoStartedAt, nil);
                [subscriber sendNext:responseObject];
                [subscriber sendCompleted];
            } faileureForError:^(NSError *error) {
                TBWeatherFinish(@"weather.geo.city_lookup", geoStartedAt, error);
                [TBBusinessMonitor breadcrumb:@"weather"
                                      message:[NSString stringWithFormat:@"城市检索失败 %@(%ld)",
                                               error.domain ?: @"", (long)error.code]
                                        level:@"warning"];
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
            __block NSArray *daily15;
            __block IndicesBaseClass *indicesModel;
            __block SunMoonBaseModel *sunMoonModel;
            __block NSString *updateTime;
            __block NSString *code;

            __block NSError *requestError;
            QWeatherConfigInstance.languageType= [QWeatherManager isEnglish]?LANGUAGE_TYPE_EN:LANGUAGE_TYPE_ZH;
            dispatch_group_t group = dispatch_group_create();
            dispatch_group_enter(group);
            QWeatherConfigInstance.location = [input objectForKey:@"cityId"];
            NSDate *nowStartedAt = [NSDate date];
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_WEATHER_NOW WithSuccess:^(WeatherBaseClass  *responseObject) {
                TBWeatherFinish(@"weather.now", nowStartedAt, nil);
                now = responseObject.now;
                updateTime = responseObject.updateTime;
                code = responseObject.code;
                dispatch_group_leave(group);
            } faileureForError:^(NSError *err) {
                TBWeatherFinish(@"weather.now", nowStartedAt, err);
                if (!requestError) { requestError = err; }
                dispatch_group_leave(group);
            }];
            dispatch_group_enter(group);
            NSDate *hourlyStartedAt = [NSDate date];
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_WEATHER_24H WithSuccess:^(WeatherBaseClass  *responseObject) {
                TBWeatherFinish(@"weather.24h", hourlyStartedAt, nil);
                hourly = responseObject.hourly;
                           dispatch_group_leave(group);
                       } faileureForError:^(NSError *err) {
                TBWeatherFinish(@"weather.24h", hourlyStartedAt, err);
                if (!requestError) { requestError = err; }
                dispatch_group_leave(group);
            }];
            dispatch_group_enter(group);
            NSDate *dailyStartedAt = [NSDate date];
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_WEATHER_3D WithSuccess:^(WeatherBaseClass  *responseObject) {
                TBWeatherFinish(@"weather.3d", dailyStartedAt, nil);
                daily = responseObject.daily;
                           dispatch_group_leave(group);
        } faileureForError:^(NSError *err) {
                TBWeatherFinish(@"weather.3d", dailyStartedAt, err);
                if (!requestError) { requestError = err; }
                dispatch_group_leave(group);
            }];
            //15天预报（含 sunrise/sunset/uvIndex/humidity/windDirDay 等）
            dispatch_group_enter(group);
            QWeatherConfigInstance.location = [input objectForKey:@"cityId"];
            QWeatherConfigInstance.languageType= [QWeatherManager isEnglish]?LANGUAGE_TYPE_EN:LANGUAGE_TYPE_ZH;
            NSDate *daily15StartedAt = [NSDate date];
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_WEATHER_15D WithSuccess:^(WeatherBaseClass  *responseObject) {
                TBWeatherFinish(@"weather.15d", daily15StartedAt, nil);
                daily15 = responseObject.daily;
                dispatch_group_leave(group);
            } faileureForError:^(NSError *err) {
                TBWeatherFinish(@"weather.15d", daily15StartedAt, err);
                // 15 天预报属于增强数据：免费套餐可能不可用，失败不应影响主流程刷新
                dispatch_group_leave(group);
            }];
            //生活指数（先设置需要的指数类型，SDK 用全局单例承载配置，保持与上面相同的串行设置模式）
            dispatch_group_enter(group);
            QWeatherConfigInstance.location = [input objectForKey:@"cityId"];
            QWeatherConfigInstance.indices = @[@(INDICES_TYPE_drsg), @(INDICES_TYPE_uv), @(INDICES_TYPE_cw), @(INDICES_TYPE_spt), @(INDICES_TYPE_comf), @(INDICES_TYPE_flu)];
            QWeatherConfigInstance.languageType= [QWeatherManager isEnglish]?LANGUAGE_TYPE_EN:LANGUAGE_TYPE_ZH;
            NSDate *indicesStartedAt = [NSDate date];
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_INDICES_1D WithSuccess:^(IndicesBaseClass  *responseObject) {
                TBWeatherFinish(@"weather.indices", indicesStartedAt, nil);
                indicesModel = responseObject;
                dispatch_group_leave(group);
            } faileureForError:^(NSError *err) {
                TBWeatherFinish(@"weather.indices", indicesStartedAt, err);
                // 生活指数为可选数据，失败时隐藏该区块即可
                dispatch_group_leave(group);
            }];
            //日月信息（日出日落/月出月落/月相）
            //和风天文接口要求 lat/lon/tz/date 必填，SDK 内部用这些值拼参数，
            //缺任意一项会在 SDK 的 setObject:forKey: 处直接抛异常（无法在调用侧 try/catch）。
            //因此拿不到坐标时直接跳过该可选请求，界面回退到 15 天预报里的日出日落。
            NSString *sunMoonLat = [input objectForKey:@"lat"];
            NSString *sunMoonLon = [input objectForKey:@"lon"];
            NSString *sunMoonTz  = [input objectForKey:@"tz"];
            if (QWeatherStrValid(sunMoonLat) && QWeatherStrValid(sunMoonLon) && QWeatherStrValid(sunMoonTz)) {
                dispatch_group_enter(group);
                NSDateFormatter *sunMoonFormatter = [[NSDateFormatter alloc] init];
                sunMoonFormatter.dateFormat = @"yyyyMMdd";
                sunMoonFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
                QWeatherConfigInstance.location = [input objectForKey:@"cityId"];
                QWeatherConfigInstance.languageType= [QWeatherManager isEnglish]?LANGUAGE_TYPE_EN:LANGUAGE_TYPE_ZH;
                QWeatherConfigInstance.lat = sunMoonLat;
                QWeatherConfigInstance.lon = sunMoonLon;
                QWeatherConfigInstance.tz = sunMoonTz;
                QWeatherConfigInstance.alt = @"0";
                QWeatherConfigInstance.date = [sunMoonFormatter stringFromDate:[NSDate date]];
                QWeatherConfigInstance.time = @"1200";
                NSDate *sunMoonStartedAt = [NSDate date];
                [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_SUNMOON WithSuccess:^(SunMoonBaseModel  *responseObject) {
                    TBWeatherFinish(@"weather.sunmoon", sunMoonStartedAt, nil);
                    sunMoonModel = responseObject;
                    dispatch_group_leave(group);
                } faileureForError:^(NSError *err) {
                    TBWeatherFinish(@"weather.sunmoon", sunMoonStartedAt, err);
                    // 日月信息为可选数据，失败不影响天气主数据
                    dispatch_group_leave(group);
                }];
            }

            if (QWeatherStrValid([input objectForKey:@"parent_city"])) {
                dispatch_group_enter(group);
                QWeatherConfigInstance.location = [input objectForKey:@"parent_city"];
                QWeatherConfigInstance.languageType= [QWeatherManager isEnglish]?LANGUAGE_TYPE_EN:LANGUAGE_TYPE_ZH;
                NSDate *parentAirStartedAt = [NSDate date];
                [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_WEATHER_AIR_NOW WithSuccess:^(AirBaseClass  *responseObject) {
                    TBWeatherFinish(@"weather.air.parent", parentAirStartedAt, nil);
                    AirBaseDataModel = responseObject;
                    dispatch_group_leave(group);
                } faileureForError:^(NSError *err) {
                    TBWeatherFinish(@"weather.air.parent", parentAirStartedAt, err);
                if (!requestError) { requestError = err; }
                dispatch_group_leave(group);
            }];
            }
            dispatch_group_enter(group);
            QWeatherConfigInstance.location = [input objectForKey:@"location"];
            QWeatherConfigInstance.languageType= [QWeatherManager isEnglish]?LANGUAGE_TYPE_EN:LANGUAGE_TYPE_ZH;
            NSDate *locationAirStartedAt = [NSDate date];
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_WEATHER_AIR_NOW WithSuccess:^(AirBaseClass  *responseObject) {
                TBWeatherFinish(@"weather.air.now", locationAirStartedAt, nil);
                locationAirBaseDataModel = responseObject;
                dispatch_group_leave(group);
            } faileureForError:^(NSError *err) {
                TBWeatherFinish(@"weather.air.now", locationAirStartedAt, err);
                if (!requestError) { requestError = err; }
                dispatch_group_leave(group);
            }];
            //预警
            dispatch_group_enter(group);
            QWeatherConfigInstance.location = [input objectForKey:@"cityId"];
            QWeatherConfigInstance.languageType= [QWeatherManager isEnglish]?LANGUAGE_TYPE_EN:LANGUAGE_TYPE_ZH;
            NSDate *warningStartedAt = [NSDate date];
            [QWeatherConfigInstance weatherWithInquireType:INQUIRE_TYPE_WARNING WithSuccess:^(WarningBaseClass  *responseObject) {
                TBWeatherFinish(@"weather.warning", warningStartedAt, nil);
                alarmBaseClass = responseObject;
                dispatch_group_leave(group);
            } faileureForError:^(NSError *error) {
                TBWeatherFinish(@"weather.warning", warningStartedAt, error);
                dispatch_group_leave(group);
            }];
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                if (requestError) {
                    // 一次首页刷新最多 9 个 SDK 请求，失败面包屑只打在「整次刷新」这一层，
                    // 不逐条打，避免 15 天预报 / 生活指数这类可选接口失败时刷屏。
                    [TBBusinessMonitor breadcrumb:@"weather"
                                          message:[NSString stringWithFormat:@"天气首页刷新失败 %@(%ld)",
                                                   requestError.domain ?: @"", (long)requestError.code]
                                            level:@"warning"];
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
                    model.daily15 = daily15;
                    model.indicesModel = indicesModel;
                    model.sunMoonModel = sunMoonModel;
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
                param[@"lat"] = city.basic.lat ?: @"";
                param[@"lon"] = city.basic.lon ?: @"";
                param[@"tz"] = city.basic.tz ?: @"";

                chain = [chain flattenMap:^RACSignal *(NSArray *results) {
                    RACSignal *one = [[[[QWeatherRequest new] homeDataCommand] execute:param] flattenMap:^RACSignal *(QWeatherHomeTabelViewDataModel *x) {
                        if (!QWeatherStrEqual(x.code, @"200")) {
                            // 单个城市失败时保留旧数据并标记状态，不影响其它城市刷新
                            city.loadState = @"failed";
                            return [RACSignal return:[results arrayByAddingObject:city]];
                        }
                        x.basic = city.basic;
                        x.lastUpdatedAt = [[NSDate date] timeIntervalSince1970];
                        x.loadState = nil;
                        return [RACSignal return:[results arrayByAddingObject:x]];
                    }];
                    return [one catch:^RACSignal *(NSError *error) {
                        city.loadState = @"failed";
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
