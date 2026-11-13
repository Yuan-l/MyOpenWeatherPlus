//
//  TBCityCatalog.m
//  MyOpenWeatherPlus
//

#import "TBCityCatalog.h"
#import "TBCityCatalogData.h"
#import <QWeather/QWeather.h>

static NSInteger const kDefaultSearchLimit = 50;
static NSInteger const kMaxSearchLimit = 200;

static NSString *TBUTF8(const char *value) {
    return value ? [NSString stringWithUTF8String:value] ?: @"" : @"";
}

@implementation TBCityItem

- (NSString *)displayName {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (NSString *part in @[self.name ?: @"", self.adm1 ?: @"", self.adm2 ?: @""]) {
        if (part.length > 0 && ![parts containsObject:part]) {
            [parts addObject:part];
        }
    }
    return parts.count > 0 ? [parts componentsJoinedByString:@" · "] : @"--";
}

- (Location *)locationValue {
    Location *location = [Location new];
    location.cid = self.cid ?: @"";
    location.name = self.name ?: @"";
    location.adm1 = self.adm1 ?: @"";
    location.adm2 = self.adm2 ?: @"";
    location.country = @"中国";
    location.lat = self.lat ?: @"";
    location.lon = self.lon ?: @"";
    location.tz = self.timezone ?: @"Asia/Shanghai";
    return location;
}

@end


@interface TBCityCatalog ()
@property (nonatomic, strong) NSArray<TBCityItem *> *cities;
@property (nonatomic, strong) NSDictionary<NSString *, TBCityItem *> *citiesByID;
@property (nonatomic, strong) NSDictionary<NSString *, TBCityItem *> *citiesByName;
@property (nonatomic, strong) NSArray<TBCityItem *> *hotCityList;
@end

@implementation TBCityCatalog

+ (instancetype)sharedCatalog {
    static TBCityCatalog *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TBCityCatalog alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadCities];
    }
    return self;
}

- (void)loadCities {
    NSMutableArray<TBCityItem *> *items = [NSMutableArray arrayWithCapacity:TBCityCatalogRecordCount];
    NSMutableDictionary<NSString *, TBCityItem *> *byID = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, TBCityItem *> *byName = [NSMutableDictionary dictionary];
    for (NSUInteger index = 0; index < TBCityCatalogRecordCount; index++) {
        const TBCityCatalogRecord *record = &TBCityCatalogRecords[index];
        TBCityItem *item = [TBCityItem new];
        item.cid = TBUTF8(record->cid);
        item.name = TBUTF8(record->name);
        item.englishName = TBUTF8(record->englishName);
        item.adm1 = TBUTF8(record->adm1);
        item.adm2 = TBUTF8(record->adm2);
        item.lat = TBUTF8(record->lat);
        item.lon = TBUTF8(record->lon);
        item.timezone = TBUTF8(record->timezone);
        [items addObject:item];
        byID[item.cid] = item;
        if (!byName[item.name]) {
            byName[item.name] = item;  // 同名城市保留第一个（通常是地级市主站）
        }
    }
    _cities = [items copy];
    _citiesByID = [byID copy];
    _citiesByName = [byName copy];
}

- (NSUInteger)cityCount {
    return self.cities.count;
}

- (NSString *)version {
    return TBCityCatalogVersion;
}

#pragma mark - 检索

/// 命中优先级：同名 > 中文前缀 > 拼音/英文前缀 > 行政区前缀 > 包含
static NSInteger TBMatchScore(TBCityItem *item, NSString *keyword) {
    NSString *name = item.name ?: @"";
    NSString *english = item.englishName ?: @"";
    NSString *adm1 = item.adm1 ?: @"";
    NSString *adm2 = item.adm2 ?: @"";
    NSStringCompareOptions options = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch;

    if ([name compare:keyword options:options] == NSOrderedSame) return 0;
    if (keyword.length > 0 && [name rangeOfString:keyword options:options range:NSMakeRange(0, name.length)].location == 0) return 1;
    if (keyword.length > 0 && [english rangeOfString:keyword options:options range:NSMakeRange(0, english.length)].location == 0) return 2;
    if (keyword.length > 0 && ([adm2 rangeOfString:keyword options:options].location == 0 ||
                               [adm1 rangeOfString:keyword options:options].location == 0)) return 3;
    if ([name rangeOfString:keyword options:options].location != NSNotFound) return 4;
    if ([english rangeOfString:keyword options:options].location != NSNotFound) return 5;
    if ([adm2 rangeOfString:keyword options:options].location != NSNotFound ||
        [adm1 rangeOfString:keyword options:options].location != NSNotFound) return 6;
    return NSIntegerMax;
}

- (NSArray<TBCityItem *> *)searchWithKeyword:(NSString *)keyword limit:(NSInteger)limit {
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return @[];
    }
    NSInteger max = limit > 0 ? MIN(limit, kMaxSearchLimit) : kDefaultSearchLimit;

    NSMutableArray<TBCityItem *> *hits = [NSMutableArray array];
    NSMutableArray<NSNumber *> *scores = [NSMutableArray array];
    for (TBCityItem *item in self.cities) {
        NSInteger score = TBMatchScore(item, trimmed);
        if (score != NSIntegerMax) {
            [hits addObject:item];
            [scores addObject:@(score)];
        }
    }
    // 相关度相同则短名字优先（例如「广州」排在「广州南沙」之前）
    NSMutableArray<NSNumber *> *order = [NSMutableArray arrayWithCapacity:hits.count];
    for (NSUInteger i = 0; i < hits.count; i++) {
        [order addObject:@(i)];
    }
    [order sortUsingComparator:^NSComparisonResult(NSNumber *left, NSNumber *right) {
        NSUInteger li = left.unsignedIntegerValue, ri = right.unsignedIntegerValue;
        NSInteger ls = scores[li].integerValue, rs = scores[ri].integerValue;
        if (ls != rs) return ls < rs ? NSOrderedAscending : NSOrderedDescending;
        NSUInteger ll = hits[li].name.length, rl = hits[ri].name.length;
        if (ll != rl) return ll < rl ? NSOrderedAscending : NSOrderedDescending;
        return [hits[li].cid compare:hits[ri].cid];
    }];

    NSMutableArray<TBCityItem *> *result = [NSMutableArray arrayWithCapacity:MIN(max, order.count)];
    for (NSNumber *index in order) {
        if ((NSInteger)result.count >= max) break;
        [result addObject:hits[index.unsignedIntegerValue]];
    }
    return [result copy];
}

#pragma mark - 常用 / 查找

- (NSArray<TBCityItem *> *)hotCities {
    if (self.hotCityList) {
        return self.hotCityList;
    }
    NSArray<NSString *> *preferredIDs = @[
        @"101010100", // 北京
        @"101020100", // 上海
        @"101280101", // 广州
        @"101280601", // 深圳
        @"101210101", // 杭州
        @"101270101", // 成都
        @"101040100", // 重庆
        @"101200101", // 武汉
        @"101110101", // 西安
        @"101190101", // 南京
        @"101030100", // 天津
        @"101220101", // 合肥
    ];
    NSMutableArray<TBCityItem *> *result = [NSMutableArray array];
    for (NSString *cid in preferredIDs) {
        TBCityItem *item = self.citiesByID[cid];
        if (item) {
            [result addObject:item];
        }
    }
    self.hotCityList = [result copy];
    return self.hotCityList;
}

- (TBCityItem *)cityWithID:(NSString *)cid {
    return cid.length > 0 ? self.citiesByID[cid] : nil;
}

- (TBCityItem *)cityWithName:(NSString *)name {
    if (name.length == 0) return nil;
    TBCityItem *exact = self.citiesByName[name];
    if (exact) return exact;
    NSArray<TBCityItem *> *hits = [self searchWithKeyword:name limit:1];
    return hits.firstObject;
}

- (TBCityItem *)itemWithLocation:(Location *)location {
    if (!location || location.cid.length == 0) {
        return nil;
    }
    TBCityItem *known = self.citiesByID[location.cid];
    if (known) {
        return known;
    }
    TBCityItem *item = [TBCityItem new];
    item.cid = location.cid ?: @"";
    item.name = location.name ?: @"";
    item.englishName = location.name ?: @"";
    item.adm1 = location.adm1 ?: @"";
    item.adm2 = location.adm2 ?: @"";
    item.lat = location.lat ?: @"";
    item.lon = location.lon ?: @"";
    item.timezone = location.tz ?: @"Asia/Shanghai";
    return item;
}

@end
