//
//  QWeatherDataManager.m
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//
//  When I wrote this, only God and I understood what I was doing
//  Now, God only knows

#define QWeatherDataCacheKey @"QWeatherDataCacheKey"
#define QWeatherDataCache [YYCache cacheWithName:QWeatherDataCacheKey]

#import "QWeatherDataManager.h"
#import <YYCache/YYCache.h>

#import "CommonMacros.h"
#import "FontAndColorMacros.h"
#import "UtilsMacros.h"
#import <Masonry/Masonry.h>
#import <QMUIKit/QMUIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>

static NSString * kcollectionDataArray = @"kcollectionDataArray";
static NSString * ksettingModel = @"ksettingModel";
static NSString * kselectedCityIndex = @"kselectedCityIndex";
static NSString * const kCH          = @"zh-Hans";
static NSString * const kCHCN         = @"zh-Hans-CN";
static NSString * const kEN          = @"en";
static NSString * const kProj        = @"lproj";

@interface QWeatherDataManager()

@property (nonatomic,strong) YYCache *dataCache;

- (void)clampSelectedCityIndex;
- (void)persistCollectionDataArray;

@end

@implementation QWeatherDataManager
SINGLETON_FOR_CLASS(QWeatherDataManager);

@synthesize selectedCityIndex = _selectedCityIndex;

-(instancetype)init{
    self = [super init];
    if (self) {
        _dataCache = QWeatherDataCache;
        [self setManager];
    }
    return self;
}
-(void)setManager{
    if ([_dataCache objectForKey:kcollectionDataArray]) {
        self.collectionDataArray = [NSMutableArray arrayWithArray:(NSArray *)[_dataCache objectForKey:kcollectionDataArray]];
    }else{
        self.collectionDataArray = [NSMutableArray array];
        [_dataCache setObject:self.collectionDataArray forKey:kcollectionDataArray];
    }
    if ([_dataCache objectForKey:ksettingModel]) {
        self.settingModel = (QWeatherSettingModel *)[_dataCache objectForKey:ksettingModel];
    }else{
        QWeatherSettingModel *model = [QWeatherSettingModel new];
        model.fontType = 1;
        model.languageType = 0;
        model.unitType = 1;
        model.isFirstOpenApp = YES;
        self.settingModel = model;
        [_dataCache setObject:model forKey:ksettingModel];
    }
    NSNumber *index = (NSNumber *)[_dataCache objectForKey:kselectedCityIndex];
    _selectedCityIndex = index.integerValue;
    [self clampSelectedCityIndex];
    [self resetBundle];
    
}

-(NSInteger)maxCityCount{
    return 10;
}

-(void)clampSelectedCityIndex{
    NSInteger count = self.collectionDataArray.count;
    if (count == 0) {
        _selectedCityIndex = 0;
    }else if (_selectedCityIndex < 0) {
        _selectedCityIndex = 0;
    }else if (_selectedCityIndex >= count) {
        _selectedCityIndex = count - 1;
    }
}

-(NSInteger)selectedCityIndex{
    [self clampSelectedCityIndex];
    return _selectedCityIndex;
}

-(void)setSelectedCityIndex:(NSInteger)selectedCityIndex{
    _selectedCityIndex = selectedCityIndex;
    [self clampSelectedCityIndex];
    [_dataCache setObject:@(_selectedCityIndex) forKey:kselectedCityIndex];
}

-(NSInteger)indexOfCityWithID:(NSString *)cid{
    if (!QWeatherStrValid(cid)) {
        return NSNotFound;
    }
    __block NSInteger found = NSNotFound;
    [self.collectionDataArray enumerateObjectsUsingBlock:^(QWeatherHomeTabelViewDataModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (QWeatherStrEqual(obj.basic.cid, cid)) {
            found = idx;
            *stop = YES;
        }
    }];
    return found;
}
-(BOOL)isFirstOpenApp{
    return self.settingModel.isFirstOpenApp;
}
-(void)setIsFirstOpenApp:(BOOL)isFirstOpenApp{
    self.settingModel.isFirstOpenApp = isFirstOpenApp;
    [_dataCache setObject:self.settingModel forKey:ksettingModel];
}
-(void)addCollectionDataArrayWithModel:(QWeatherHomeTabelViewDataModel *)model isLoaction:(BOOL)isLoaction{
    [self addCityModel:model isLocation:isLoaction];
}

-(BOOL)addCityModel:(QWeatherHomeTabelViewDataModel *)model isLocation:(BOOL)isLocation{
    if (!model) {
        return NO;
    }

    if (isLocation) {
        if (self.collectionDataArray.count > 0) {
            [self.collectionDataArray replaceObjectAtIndex:0 withObject:model];
        }else{
            [self.collectionDataArray addObject:model];
        }
        [self persistCollectionDataArray];
        return YES;
    }

    NSInteger existing = [self indexOfCityWithID:model.basic.cid];
    if (existing == 0) {
        // 与定位城市重复：保留定位城市，视为切换成功
        [self persistCollectionDataArray];
        return YES;
    }
    if (existing != NSNotFound) {
        [self.collectionDataArray removeObjectAtIndex:existing];
    }

    if (self.collectionDataArray.count >= self.maxCityCount) {
        // 达到上限不静默删城市，恢复被移除的重复项并提示调用方
        if (existing != NSNotFound) {
            NSInteger restore = MIN(existing, (NSInteger)self.collectionDataArray.count);
            [self.collectionDataArray insertObject:model atIndex:restore];
        }
        [self persistCollectionDataArray];
        return NO;
    }

    if (self.collectionDataArray.count == 0) {
        [self.collectionDataArray addObject:model];
    }else{
        [self.collectionDataArray insertObject:model atIndex:1];
    }
    [self persistCollectionDataArray];
    return YES;
}

-(BOOL)moveCityFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex{
    NSInteger count = self.collectionDataArray.count;
    if (fromIndex < 0 || fromIndex >= count || toIndex < 0 || toIndex >= count || fromIndex == toIndex) {
        return NO;
    }
    QWeatherHomeTabelViewDataModel *model = self.collectionDataArray[fromIndex];
    [self.collectionDataArray removeObjectAtIndex:fromIndex];
    [self.collectionDataArray insertObject:model atIndex:toIndex];

    NSInteger selected = self.selectedCityIndex;
    if (selected == fromIndex) {
        _selectedCityIndex = toIndex;
    }else if (fromIndex < selected && toIndex >= selected) {
        _selectedCityIndex = selected - 1;
    }else if (fromIndex > selected && toIndex <= selected) {
        _selectedCityIndex = selected + 1;
    }
    [self persistCollectionDataArray];
    return YES;
}

-(void)persistCollectionDataArray{
    [self clampSelectedCityIndex];
    [_dataCache setObject:self.collectionDataArray forKey:kcollectionDataArray];
    [_dataCache setObject:@(_selectedCityIndex) forKey:kselectedCityIndex];
}

-(void)delCollectionDataArrayWithIndex:(NSInteger)index{
    if (index < 0 || index >= (NSInteger)self.collectionDataArray.count) {
        return;
    }
    [self.collectionDataArray removeObjectAtIndex:index];
    NSInteger selected = self.selectedCityIndex;
    if (selected > index) {
        _selectedCityIndex = selected - 1;
    }else if (selected == index) {
        _selectedCityIndex = MIN(index, (NSInteger)self.collectionDataArray.count - 1);
    }
    [self persistCollectionDataArray];
}
-(void)updateCollectionDataArrayWithArray:(NSArray *)array{
    self.collectionDataArray = [NSMutableArray arrayWithArray:array];
    [self persistCollectionDataArray];
}
-(void)updateSettingWithIndex:(NSInteger)index{
    switch (index) {
        case 1:
            self.settingModel.languageType = 0;
            break;
        case 2:
            self.settingModel.languageType = 1;
            break;
        case 3:
            self.settingModel.languageType = 2;
            break;
        case 4:
            self.settingModel.unitType = 0;
            break;
        case 5:
            self.settingModel.unitType = 1;
            break;
        case 6:
            self.settingModel.fontType = 0;
            break;
        case 7:
            self.settingModel.fontType = 1;
            break;
        case 8:
            self.settingModel.fontType = 2;
            break;
        default:
            break;
    }
    
    [_dataCache setObject:self.settingModel forKey:ksettingModel];
    if (index==1||index==2||index==3) {
        [self resetBundle];
        QWeatherPostNotification(KNotificationRefreshHomeData, nil);
    }
    QWeatherPostNotification(KNotificationChangeTextSetting, nil);
}
- (void)resetBundle{
    if (self.settingModel.languageType==0) {
        NSArray *languages = [NSLocale preferredLanguages];
        NSString *currentLanguage = [languages objectAtIndex:0];
        if (QWeatherStrEqual(currentLanguage, kCHCN)||QWeatherStrEqual(currentLanguage, kCH)) {
            NSString *path = [[NSBundle mainBundle] pathForResource:kCH ofType:kProj];
            self.bundle = [NSBundle bundleWithPath:path];
        }else{
            NSString *path = [[NSBundle mainBundle] pathForResource:kEN ofType:kProj];
            self.bundle = [NSBundle bundleWithPath:path];
        }
    }else if (self.settingModel.languageType==1) {
        NSString *path = [[NSBundle mainBundle] pathForResource:kCH ofType:kProj];
        self.bundle = [NSBundle bundleWithPath:path];
    }else{
        NSString *path = [[NSBundle mainBundle] pathForResource:kEN ofType:kProj];
        self.bundle = [NSBundle bundleWithPath:path];
    }
}
- (NSString *)stringWithKey:(NSString *)key table:(NSString *)table
{
    if (_bundle) {
        return  NSLocalizedStringFromTableInBundle(key, table, _bundle, nil);
    }
    return NSLocalizedStringFromTable(key, table, nil);
}

-(BOOL)isEnglish{
    if (self.settingModel.languageType==1) {
        return NO;
    }else if (self.settingModel.languageType==0){
        NSArray *languages = [NSLocale preferredLanguages];
        NSString *currentLanguage = [languages objectAtIndex:0];
        if (QWeatherStrEqual(currentLanguage, kCHCN)||QWeatherStrEqual(currentLanguage, kCH)) {
            return NO;
        }else{
            return YES;
        }
    }else{
        return YES;
    }
}

@end
