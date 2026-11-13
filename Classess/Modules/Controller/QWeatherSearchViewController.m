//
//  QWeatherSearchViewController.m
//  OpenWeatherPlus
//
//  添加城市：先用组件内置的全量离线城市库检索（3577 个中国城市，支持中文/拼音/省份），
//  只有本地完全没有命中时才用和风 GEO 补一次网络结果（主要用于海外城市）。
//  点击结果直接把完整的城市对象交给首页落库，不再「传城市名 → 首页再 GEO 查一次」。
//

#import "QWeatherSearchViewController.h"
#import "QWeatherSearchBarView.h"
#import "QWeatherSearchCell.h"
#import "QWeatherCollectionCityCell.h"
#import "QWeatherRequest.h"
#import "QWeatherDataManager.h"
#import "TBCityCatalog.h"
#import "QWeatherTool.h"
#import <YYText/YYText.h>
#import <QWeather/QWeather.h>

#import "CommonMacros.h"
#import "FontAndColorMacros.h"
#import "UtilsMacros.h"
#import <Masonry/Masonry.h>
#import <QMUIKit/QMUIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface QWeatherSearchViewController ()<UITableViewDelegate,UITableViewDataSource,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
@property (nonatomic,strong) QWeatherSearchBarView *searchView;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UICollectionView *collectionView;
@property (nonatomic,strong) UILabel *statusLabel;
@property (nonatomic,strong) QWeatherRequest *weatherRequest;
@property (nonatomic,strong) NSArray<TBCityItem *> *searchCityArray;
@property (nonatomic,strong) NSArray<TBCityItem *> *citysArray;
@property (nonatomic,copy) NSString *searchText;
@property (nonatomic,copy) NSString *networkHint;
@end

@implementation QWeatherSearchViewController

- (BOOL)shouldHideKeyboardWhenTouchInView:(UIView *)view{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleView.title = QWeatherLocal(@"hengfengLocalString_36");
    self.searchCityArray = @[];
    [self configUI];
    [self configLayout];
    [self reload];
}

-(void)configUI{
    [self.view addSubview:self.searchView];
    [self.view addSubview:self.statusLabel];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.collectionView];

    @weakify(self)
    [[[[self.searchView.searchTextField rac_textSignal] skip:1] throttle:0.2] subscribeNext:^(NSString * _Nullable x) {
        @strongify(self)
        NSString *keyword = [x qmui_trimAllWhiteSpace];
        self.searchText = keyword;
        self.networkHint = nil;
        // 本地库即时出结果，不依赖网络、不依赖 SDK 鉴权
        self.searchCityArray = [[TBCityCatalog sharedCatalog] searchWithKeyword:keyword limit:50];
        [self reload];
        if (keyword.length > 0 && self.searchCityArray.count == 0) {
            [self searchRemoteWithKeyword:keyword];
        }
    }];
}

/// 本地库无命中时才走网络，用于补充海外城市。
-(void)searchRemoteWithKeyword:(NSString *)keyword{
    @weakify(self)
    [[[self.weatherRequest.citySearchCommand execute:@{@"location":keyword}] deliverOnMainThread]
     subscribeNext:^(GeoBaseClass *result) {
        @strongify(self)
        if (!QWeatherStrEqual(self.searchText, keyword)) {
            return;  // 丢弃过期响应
        }
        NSMutableArray<TBCityItem *> *merged = [NSMutableArray arrayWithArray:self.searchCityArray];
        NSMutableSet<NSString *> *seen = [NSMutableSet set];
        for (TBCityItem *item in merged) {
            if (item.cid.length > 0) [seen addObject:item.cid];
        }
        for (Location *location in (result.location ?: @[])) {
            TBCityItem *item = [[TBCityCatalog sharedCatalog] itemWithLocation:location];
            if (item && item.cid.length > 0 && ![seen containsObject:item.cid]) {
                [seen addObject:item.cid];
                [merged addObject:item];
            }
        }
        self.searchCityArray = [merged copy];
        self.networkHint = merged.count > 0 ? @"已补充网络检索结果" : nil;
        [self reload];
    } error:^(NSError * _Nullable error) {
        @strongify(self)
        if (!QWeatherStrEqual(self.searchText, keyword)) {
            return;
        }
        QWeatherLogWarn(@"城市网络检索失败：%@", error);
        self.networkHint = @"网络检索暂不可用，可试试中文名 / 拼音 / 省份名";
        [self reload];
    }];
}

-(void)reload{
    BOOL searching = self.searchText.length > 0;
    self.collectionView.hidden = searching;
    self.tableView.hidden = !searching;

    if (!searching) {
        self.statusLabel.text = [NSString stringWithFormat:@"常用城市 · 本地城市库共 %lu 个城市可直接搜索",
                                 (unsigned long)[TBCityCatalog sharedCatalog].cityCount];
    } else if (self.searchCityArray.count > 0) {
        self.statusLabel.text = [NSString stringWithFormat:@"找到 %lu 个城市%@",
                                 (unsigned long)self.searchCityArray.count,
                                 self.networkHint ?: @""];
    } else {
        self.statusLabel.text = self.networkHint ?: @"没有匹配的城市，换个关键词试试";
    }
    [self.tableView reloadData];
    [self.collectionView reloadData];
}

-(void)configLayout{
    [self.searchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuide);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(56);
    }];
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.searchView.mas_bottom);
        make.left.mas_equalTo(Space_16);
        make.right.mas_equalTo(-Space_16);
        make.height.mas_equalTo(40);
    }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.top.equalTo(self.statusLabel.mas_bottom);
    }];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tableView);
    }];
}

#pragma mark - 选中城市

-(void)selectCity:(TBCityItem *)item{
    if (!item) {
        return;
    }
    if (self.isSelectLocatin) {
        // 定位城市选择：沿用既有 selectLocation 流程（首页按 cid 反查并替换第 0 位）
        QWeatherManager.selectLocation = item.cid;
        QWeatherPostNotification(KNotificationRestRootVC, nil);
        return;
    }
    // 添加城市：携带完整城市信息，首页立即落库，网络失败也保留城市
    QWeatherPostNotification(KNotificationAddCity, item);
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark UITableViewDelegate,UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.searchText.length > 0 ? (NSInteger)self.searchCityArray.count : 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    QWeatherSearchCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([QWeatherSearchCell class])];
    TBCityItem *item = self.searchCityArray[indexPath.row];
    NSString *title = [item displayName];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:title];
    text.yy_color = QWeatherColor_7A7A7A;
    NSRange hit = [title rangeOfString:self.searchText ?: @""
                               options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
    if (hit.location != NSNotFound) {
        [text yy_setColor:QWeatherColor_ED802D range:hit];
    }
    cell.titleLabel.attributedText = text;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= (NSInteger)self.searchCityArray.count) {
        return;
    }
    [self selectCity:self.searchCityArray[indexPath.row]];
}

#pragma mark ---- UICollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return (NSInteger)self.citysArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    QWeatherCollectionCityCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([QWeatherCollectionCityCell class]) forIndexPath:indexPath];
    cell.titleLabel.text = self.citysArray[indexPath.row].name;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return (CGSize){(collectionView.qmui_width-Space_16*4)/3,40};
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(Space_16, Space_16, 0, Space_16);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return Space_16;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row >= (NSInteger)self.citysArray.count) {
        return;
    }
    [self selectCity:self.citysArray[indexPath.row]];
}

#pragma mark - Lazy

-(UICollectionView *)collectionView{
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:[UICollectionViewFlowLayout new]];
        [_collectionView registerClass:[QWeatherCollectionCityCell class] forCellWithReuseIdentifier:NSStringFromClass([QWeatherCollectionCityCell class])];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = QWeatherColor_ECECEC;
    }
    return _collectionView;
}

-(QWeatherSearchBarView *)searchView{
    if (!_searchView) {
        _searchView = [QWeatherSearchBarView new];
    }
    return _searchView;
}

-(UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = QWeatherColor_ECECEC;
        [_tableView registerClass:[QWeatherSearchCell class] forCellReuseIdentifier:NSStringFromClass([QWeatherSearchCell class])];
    }
    return _tableView;
}

-(QWeatherRequest *)weatherRequest{
    if (!_weatherRequest) {
        _weatherRequest = [QWeatherRequest new];
    }
    return _weatherRequest;
}

-(NSArray<TBCityItem *> *)citysArray{
    if (!_citysArray) {
        _citysArray = [[TBCityCatalog sharedCatalog] hotCities];
    }
    return _citysArray;
}

-(UILabel *)statusLabel{
    if (!_statusLabel) {
        _statusLabel = [UILabel new];
        _statusLabel.font = [UIFont systemFontOfSize:12];
        _statusLabel.textColor = QWeatherColor_7A7A7A;
        _statusLabel.numberOfLines = 2;
    }
    return _statusLabel;
}

@end
