//
//  QWeatherTool.m
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//
//  When I wrote this, only God and I understood what I was doing
//  Now, God only knows

#import "QWeatherTool.h"
#import "QWeatherDataManager.h"
#import <QWeather/QWeather.h>

#import <AMapFoundationKit/AMapFoundationKit.h>
#import <CoreLocation/CoreLocation.h>
#import <QMUIKit/QMUIKit.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

#import <DateTools/NSDate+DateTools.h>

#import "CommonMacros.h"
#import "FontAndColorMacros.h"
#import "UtilsMacros.h"
#import <Masonry/Masonry.h>
#import <QMUIKit/QMUIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface QWeatherTool ()
+ (UIImage *)gradientImageForWeatherCode:(NSString *)weatherCode isDay:(BOOL)isDay;
+ (UIImage *)symbolImageForWeatherCode:(NSString *)weatherCode isDay:(BOOL)isDay;
@end

@implementation QWeatherTool

+(void)initLog{
    
    [QMUIConfiguration sharedInstance].shouldPrintDefaultLog = NO;
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    //保存日志
    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:[[DDLogFileManagerDefault alloc]initWithLogsDirectory:kPathCache]];
    fileLogger.rollingFrequency = 60 * 60 * 24;
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:fileLogger withLevel:DDLogLevelWarning];
    
    if (QWeatherStrValid(KAMapLocationAPPKey)) {
        [AMapServices sharedServices].apiKey = KAMapLocationAPPKey;
    }else{
        QWeatherLogWarn(@"请添加高德定位key👉🏻👉🏻👉🏻（替换KAMapLocationAPPKey的值）");
    }
    
    if (QWeatherStrValid(HeWeatherSDK_USERNameKey)||QWeatherStrValid(HeWeatherSDK_USERKey)) {
        QWeatherConfigInstance.publicID = HeWeatherSDK_USERNameKey;
        QWeatherConfigInstance.appKey = HeWeatherSDK_USERKey;
        QWeatherConfigInstance.appType = APP_TYPE_BIZ;
    }else{
        QWeatherLogWarn(@"请添加和风天气的key👉🏻👉🏻👉🏻（替换HeWeatherSDK_USERNameKey和HeWeatherSDK_USERKey的值）");
    }
}

+(BOOL)isLocationAuthorizationStatusDenied{
    //用户没有选择是否要使用定位服务（弹框没选择，或者根本没有弹框）
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        return NO;
        //用户在设置中关闭定位功能，或者用户明确的在弹框之后选择禁止定位
    }else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
        QMUIAlertController *alertController = [QMUIAlertController alertControllerWithTitle:QWeatherLocal(@"hengfengLocalString_46") message:nil preferredStyle:QMUIAlertControllerStyleAlert];
        //        UIView *view = [UIView new];
        //        view.backgroundColor = kRandomColor;
        //        view.qmui_width = 100;
        //        view.qmui_height = 100;
        //        [alertController addCustomView:view];
        [alertController addAction:[QMUIAlertAction actionWithTitle:QWeatherLocal(@"hengfengLocalString_51") style:QMUIAlertActionStyleDefault handler:^(__kindof QMUIAlertController *aAlertController, QMUIAlertAction *action) {
            if (@available(iOS 8.0, *)) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([kApplication canOpenURL:url]) {
                    [kApplication openURL:url];
                }
            } else {
                [kApplication openURL:[NSURL URLWithString:@"prefs:root=LOCATION_SERVICES"]];
            }
        }]];
        [alertController addAction:[QMUIAlertAction actionWithTitle:QWeatherLocal(@"hengfengLocalString_49") style:QMUIAlertActionStyleDefault handler:nil]];
        [alertController showWithAnimated:YES];
        return YES;
    }else{
        return NO;
    }
}

+(NSString *)getTempStringWithString:(NSString *)string isHaveUnit:(BOOL)isHaveUnit{
    CGFloat temp = string.floatValue;
    if (QWeatherManager.settingModel.unitType==1) {
        return  QWeatherStringFormat(@"%ld%@",(long)[@(temp) integerValue],isHaveUnit?@"°":@"");
    }else{
        return  QWeatherStringFormat(@"%ld%@",(long)[@(temp*1.8) integerValue]+32,isHaveUnit?@"°":@"");
    }
}

+(NSString *)getTimeStringWithSting:(NSString *)string dateformat:(NSString *)dateformat isShowToday:(BOOL)isShowToday{
    NSDate *date = [NSDate dateWithString:string formatString:dateformat];
    NSArray *titlesArray = [NSArray arrayWithObjects: @"", @"hengfengLocalString_43", @"hengfengLocalString_37", @"hengfengLocalString_38", @"hengfengLocalString_39", @"hengfengLocalString_40", @"hengfengLocalString_41", @"hengfengLocalString_42", nil];
    if (isShowToday&&[date isToday]) {
        return  @"hengfengLocalString_44";
    }else{
        return  titlesArray[[date weekday]];
    }
}

+(UIImage *)getWeatherImageWithWeatherCode:(NSString *)weatherCode date:(NSString *)date formatString:(nonnull NSString *)formatString{
    return  [self getWeatherImageWithWeatherCode:weatherCode isDay:[self isDayWithStr:date] formatString:formatString];
}

+(UIImage *)getWeatherImageWithWeatherCode:(NSString *)weatherCode isDay:(BOOL)isDay formatString:(nonnull NSString *)formatString{
    NSString *imageName = QWeatherStringFormat(@"%@%@%@",formatString,weatherCode,isDay?@"d":@"n");
    UIImage *image = UIImageMake(imageName);

    // 本地组件没有携带原始天气资源，这里做一层兜底：
    // - 背景图退化为渐变色，避免白字白底导致文字完全不可见
    // - 天气图标退化为 SF Symbols，保证列表信息仍然可读
    if (image) {
        return image;
    }

    if ([formatString isEqualToString:QWeatherBgImageFormatString]) {
        return [self gradientImageForWeatherCode:weatherCode isDay:isDay];
    }

    if ([formatString isEqualToString:QWeatherImageFormatString]) {
        return [self symbolImageForWeatherCode:weatherCode isDay:isDay];
    }

    return nil;
}

#pragma mark - 缺失资源兜底

+ (NSCache<NSString *, UIImage *> *)weatherImageCache {
    static NSCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSCache new];
        cache.countLimit = 32;
    });
    return cache;
}

+ (NSArray<UIColor *> *)gradientColorsForWeatherCode:(NSString *)weatherCode isDay:(BOOL)isDay {
    NSInteger code = weatherCode.integerValue;

    // 晴天
    if (code >= 100 && code <= 103) {
        return isDay
            ? @[kQWeatherColor(@"#2E7CF6"), kQWeatherColor(@"#7FB8FF")]
            : @[kQWeatherColor(@"#101A33"), kQWeatherColor(@"#2E4270")];
    }
    // 多云 / 阴天
    if (code == 104 || code == 154) {
        return isDay
            ? @[kQWeatherColor(@"#5B6E88"), kQWeatherColor(@"#9FB0C4")]
            : @[kQWeatherColor(@"#1C2534"), kQWeatherColor(@"#46566D")];
    }
    // 雨
    if (code >= 300 && code <= 399) {
        return isDay
            ? @[kQWeatherColor(@"#37506E"), kQWeatherColor(@"#7492B2")]
            : @[kQWeatherColor(@"#131C2A"), kQWeatherColor(@"#354A63")];
    }
    // 雪
    if (code >= 400 && code <= 499) {
        return isDay
            ? @[kQWeatherColor(@"#5C7186"), kQWeatherColor(@"#C4D5E5")]
            : @[kQWeatherColor(@"#1B2533"), kQWeatherColor(@"#465A70")];
    }
    // 雾 / 霾 / 沙尘
    if (code >= 500 && code <= 599) {
        return isDay
            ? @[kQWeatherColor(@"#7A818B"), kQWeatherColor(@"#C3C8CF")]
            : @[kQWeatherColor(@"#1E232B"), kQWeatherColor(@"#4A515B")];
    }
    // 夜间保留更深的底色
    if (!isDay) {
        return @[kQWeatherColor(@"#101A33"), kQWeatherColor(@"#354A70")];
    }
    return @[kQWeatherColor(@"#4A6FA5"), kQWeatherColor(@"#8FB3D9")];
}

+ (UIImage *)gradientImageForWeatherCode:(NSString *)weatherCode isDay:(BOOL)isDay {
    NSString *cacheKey = QWeatherStringFormat(@"bg_%@_%@", weatherCode ?: @"", isDay ? @"d" : @"n");
    UIImage *cached = [[self weatherImageCache] objectForKey:cacheKey];
    if (cached) {
        return cached;
    }

    NSArray<UIColor *> *colors = [self gradientColorsForWeatherCode:weatherCode isDay:isDay];
    CGSize size = CGSizeMake(80, 160);
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = 1;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        CGContextRef ctx = context.CGContext;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        NSArray *cgColors = @[(__bridge id)colors.firstObject.CGColor, (__bridge id)colors.lastObject.CGColor];
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)cgColors, NULL);
        CGContextDrawLinearGradient(ctx, gradient, CGPointZero, CGPointMake(0, size.height), 0);
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);
    }];

    if (image) {
        [[self weatherImageCache] setObject:image forKey:cacheKey];
    }
    return image;
}

+ (NSString *)symbolNameForWeatherCode:(NSString *)weatherCode isDay:(BOOL)isDay {
    NSInteger code = weatherCode.integerValue;

    if (code >= 100 && code <= 103) {
        return isDay ? @"sun.max.fill" : @"moon.stars.fill";
    }
    if (code == 104 || code == 154) {
        return @"cloud.fill";
    }
    if (code >= 300 && code <= 399) {
        return code >= 310 ? @"cloud.heavyrain.fill" : @"cloud.rain.fill";
    }
    if (code >= 400 && code <= 499) {
        return @"cloud.snow.fill";
    }
    if (code >= 500 && code <= 599) {
        return @"cloud.fog.fill";
    }
    if (code >= 900 && code <= 999) {
        return @"tornado";
    }
    return isDay ? @"cloud.sun.fill" : @"cloud.moon.fill";
}

+ (UIImage *)symbolImageForWeatherCode:(NSString *)weatherCode isDay:(BOOL)isDay {
    NSString *cacheKey = QWeatherStringFormat(@"icon_%@_%@", weatherCode ?: @"", isDay ? @"d" : @"n");
    UIImage *cached = [[self weatherImageCache] objectForKey:cacheKey];
    if (cached) {
        return cached;
    }

    UIImageSymbolConfiguration *configuration =
        [UIImageSymbolConfiguration configurationWithPointSize:28 weight:UIImageSymbolWeightMedium];
    UIImage *symbol = [UIImage systemImageNamed:[self symbolNameForWeatherCode:weatherCode isDay:isDay]
                             withConfiguration:configuration];
    UIImage *image = [symbol imageWithTintColor:kQWeatherColor(@"#4A6FA5") renderingMode:UIImageRenderingModeAlwaysOriginal];

    if (image) {
        [[self weatherImageCache] setObject:image forKey:cacheKey];
    }
    return image;
}
+(BOOL)isDayWithStr:(NSString*)str{
    NSInteger  hour = [NSDate dateWithString:str formatString:QWeatherFormatString1].hour;
    if (hour>19||hour<07) {
        return NO;
    }
    else{
        return YES;
    }
}
+(UIFont *)getFontWithFontSize:(CGFloat)FontSize{
    switch (QWeatherManager.settingModel.fontType) {
        case 0:
            return QWeatherAdaptedSmallFontSize(FontSize);
            break;
        case 1:
            return QWeatherAdaptedMediumFontSize(FontSize);
            break;
        case 2:
            return QWeatherAdaptedLargeFontSize(FontSize);
            break;
        default:
            return QWeatherAdaptedMediumFontSize(FontSize);;
            break;
    }
}

+(UIColor *)getAqiColorWithString:(NSString *)string{
    NSInteger aqi = string.integerValue;
    if (aqi<=50) {
        return kQWeatherColor(@"#95B359");
    }else if (aqi<=100){
        return kQWeatherColor(@"#D9D459");
    }
    else if (aqi<=150){
        return kQWeatherColor(@"#E0991D");
    }
    else if (aqi<=200){
        return kQWeatherColor(@"#D96161");
    }
    else if (aqi<=300){
        return kQWeatherColor(@"#CB91F0");
    }
    else{
        return kQWeatherColor(@"#D9416F");
    }
}

@end
