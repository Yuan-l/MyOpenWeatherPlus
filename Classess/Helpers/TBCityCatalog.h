//
//  TBCityCatalog.h
//  MyOpenWeatherPlus
//
//  组件内置的离线城市目录。城市搜索/添加/切换不依赖网络，
//  数据由 tools/build_city_catalog.py 从和风官方城市列表生成。
//

#import <Foundation/Foundation.h>

@class Location;

NS_ASSUME_NONNULL_BEGIN

@interface TBCityItem : NSObject

@property (nonatomic, copy) NSString *cid;          // 和风 Location_ID
@property (nonatomic, copy) NSString *name;         // 中文名
@property (nonatomic, copy) NSString *englishName;  // 英文名/拼音
@property (nonatomic, copy) NSString *adm1;         // 省级行政区
@property (nonatomic, copy) NSString *adm2;         // 地级行政区
@property (nonatomic, copy) NSString *lat;
@property (nonatomic, copy) NSString *lon;
@property (nonatomic, copy) NSString *timezone;

/// 「广州 · 广东 · 广州市」这样的可读标题（去空、去重）
- (NSString *)displayName;
/// 转换成和风 SDK 的 Location，供首页数据模型直接使用
- (Location *)locationValue;

@end


@interface TBCityCatalog : NSObject

+ (instancetype)sharedCatalog;

@property (nonatomic, readonly) NSUInteger cityCount;
@property (nonatomic, readonly, copy) NSString *version;

/// 本地检索：中文名 / 英文名（拼音）/ 省 / 市，按相关度排序。limit <= 0 时用默认值 50。
- (NSArray<TBCityItem *> *)searchWithKeyword:(NSString *)keyword limit:(NSInteger)limit;

/// 常用城市（按固定顺序，找不到时自动回退到本地匹配）
- (NSArray<TBCityItem *> *)hotCities;

- (nullable TBCityItem *)cityWithID:(NSString *)cid;
- (nullable TBCityItem *)cityWithName:(NSString *)name;

/// 把网络 GEO 结果转换成本地目录条目，用于补充海外城市
- (nullable TBCityItem *)itemWithLocation:(Location *)location;

@end

NS_ASSUME_NONNULL_END
