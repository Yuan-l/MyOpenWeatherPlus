//
//  TBCityCatalogTests.m
//  MyOpenWeatherPlus Tests
//
//  城市目录的回归测试：覆盖全量数据、中文/拼音/省份检索与热门城市。
//  通过 MyOpenWeatherPlus.podspec 的 test_spec 独立编译，不进入主 App。
//

#import <XCTest/XCTest.h>
#import <QWeather/QWeather.h>
#import "TBCityCatalog.h"

@interface TBCityCatalogTests : XCTestCase
@end

@implementation TBCityCatalogTests

- (void)testCatalogIsComplete {
    XCTAssertGreaterThan([TBCityCatalog sharedCatalog].cityCount, 3000,
                         @"本地城市库应包含全量中国城市，而不是十几个硬编码热门城市");
    XCTAssertNotNil([TBCityCatalog sharedCatalog].version);
}

- (void)testChineseNameSearch {
    NSArray<TBCityItem *> *hits = [[TBCityCatalog sharedCatalog] searchWithKeyword:@"广州" limit:10];
    XCTAssertGreaterThan(hits.count, 0);
    XCTAssertEqualObjects(hits.firstObject.name, @"广州");
    XCTAssertTrue(hits.firstObject.cid.length > 0);
    XCTAssertTrue(hits.firstObject.lat.length > 0);
}

- (void)testPinyinSearch {
    NSArray<TBCityItem *> *hits = [[TBCityCatalog sharedCatalog] searchWithKeyword:@"guangzhou" limit:10];
    XCTAssertGreaterThan(hits.count, 0, @"拼音/英文名也应能检索到城市");
}

- (void)testProvinceSearch {
    NSArray<TBCityItem *> *hits = [[TBCityCatalog sharedCatalog] searchWithKeyword:@"广东" limit:50];
    XCTAssertGreaterThan(hits.count, 10, @"省份名应能带出下属城市");
    XCTAssertLessThanOrEqual(hits.count, 50);
}

- (void)testHotCitiesAreResolvable {
    NSArray<TBCityItem *> *hot = [[TBCityCatalog sharedCatalog] hotCities];
    XCTAssertGreaterThanOrEqual(hot.count, 8);
    for (TBCityItem *item in hot) {
        XCTAssertNotNil([[TBCityCatalog sharedCatalog] cityWithID:item.cid]);
    }
}

- (void)testUnknownKeywordReturnsEmpty {
    XCTAssertEqual([[TBCityCatalog sharedCatalog] searchWithKeyword:@"zzzz-not-a-city" limit:10].count, 0);
    XCTAssertEqual([[TBCityCatalog sharedCatalog] searchWithKeyword:@"" limit:10].count, 0);
}

- (void)testLocationValueCarriesWeatherRequestFields {
    TBCityItem *item = [[TBCityCatalog sharedCatalog] cityWithName:@"北京"];
    XCTAssertNotNil(item);
    Location *location = [item locationValue];
    XCTAssertEqualObjects(location.cid, item.cid);
    XCTAssertTrue(location.lat.floatValue != 0);
    XCTAssertTrue(location.lon.floatValue != 0);
    XCTAssertTrue(location.tz.length > 0);
}

@end
