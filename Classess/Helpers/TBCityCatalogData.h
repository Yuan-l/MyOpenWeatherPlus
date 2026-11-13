//
//  TBCityCatalogData.h
//  MyOpenWeatherPlus
//
//  由 tools/build_city_catalog.py 生成，请勿手工编辑。
//  数据源：China-City-List v202506200
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    const char *cid;         // 和风 Location_ID，直接用于天气接口
    const char *name;        // 中文名
    const char *englishName; // 英文名/拼音，支持拼音检索
    const char *adm1;        // 省级行政区
    const char *adm2;        // 地级行政区
    const char *lat;
    const char *lon;
    const char *timezone;
} TBCityCatalogRecord;

extern const TBCityCatalogRecord TBCityCatalogRecords[];
extern const NSUInteger TBCityCatalogRecordCount;
extern NSString * const TBCityCatalogVersion;

NS_ASSUME_NONNULL_END
