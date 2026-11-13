//
//  QWeatherHomeViewController.m
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//

#import "QWeatherHomeViewController.h"
#import "QWeatherSettingViewController.h"
#import "QWeatherSearchViewController.h"
#import "QWeatherHomeCollectionViewCell.h"
#import "QWeatherHomeNavView.h"
#import "QWeatherRequest.h"
#import "QWeatherDataManager.h"
#import "QWeatherCityManagerViewController.h"
#import "TBWeatherCityBar.h"
#import "TBCityCatalog.h"
#import "QWeatherTool.h"
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapLocationKit/AMapLocationManager.h>
#import <QWeather/QWeather.h>

#import <FDFullscreenPopGesture/UINavigationController+FDFullscreenPopGesture.h>

#import "CommonMacros.h"
#import "FontAndColorMacros.h"
#import "UtilsMacros.h"
#import <Masonry/Masonry.h>
#import <QMUIKit/QMUIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface QWeatherHomeViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,AMapLocationManagerDelegate>
@property (nonatomic,strong) UICollectionView *weatherCollectionView;
@property (nonatomic,strong) QWeatherHomeNavView *homeNavView;
@property (nonatomic,strong) TBWeatherCityBar *cityBar;
@property (nonatomic,strong) QWeatherRequest *weatherRequest;
@property (nonatomic,strong) AMapLocationManager *locationManager;
@property (nonatomic,strong) UILabel *emptyLabel;
@property (nonatomic,strong) UILabel *errorHintLabel;
@end

@implementation QWeatherHomeViewController

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [QWeatherTool initLog];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fd_prefersNavigationBarHidden = YES;
    [self updateMapManager];
    [self configUI];
    [self configLayout];
    [self addNotice];

#if DEBUG
    // 真机无点击自动化时，用 TB_AUTO_CITY=1 自动进入城市搜索页，校验标题/返回按钮位置
    if ([[[NSProcessInfo processInfo] environment][@"TB_AUTO_CITY"] isEqualToString:@"1"]) {
        __weak typeof(self) wself = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(wself) sself = wself;
            if (sself.navigationController.topViewController == sself) {
                [sself.navigationController pushViewController:[QWeatherSearchViewController new] animated:YES];
            }
        });
    }
#endif
}

-(void)addNotice{
    [[QWeatherNotificationCenter rac_addObserverForName:KNotificationOpenSafari object:nil ]subscribeNext:^(NSNotification * _Nullable x) {
        [kApplication openURL:[NSURL URLWithString:@"https://www.heweather.com"]];
    }];
    
    [[QWeatherNotificationCenter rac_addObserverForName:KNotificationRefreshCity object:nil ]subscribeNext:^(NSNotification * _Nullable x) {
        [self getDataWithLocation:x.object isLoaction:NO];
    }];
    // 添加城市：直接接收完整城市对象，先落库再异步补天气数据，网络失败也保留城市
    [[QWeatherNotificationCenter rac_addObserverForName:KNotificationAddCity object:nil ]subscribeNext:^(NSNotification * _Nullable x) {
        if ([x.object isKindOfClass:[TBCityItem class]]) {
            [self addCityWithItem:(TBCityItem *)x.object isLocation:NO];
        }
    }];
    @weakify(self)
    [[QWeatherNotificationCenter rac_addObserverForName:KNotificationRefreshHomeData object:nil ]subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self)
        [self reloadHomeData];
        [[self.weatherRequest.upDateHomeDataCommand execute:nil] subscribeNext:^(id  _Nullable x) {
            @strongify(self)
            [self reloadHomeData];
            QWeatherPostNotification(KNotificationRefreshEnd, nil);
        } error:^(NSError * _Nullable error) {
            QWeatherPostNotification(KNotificationRefreshEnd, nil);
        }];
    }];
    [[self.homeNavView.locationAddButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self.navigationController pushViewController:[QWeatherSearchViewController new] animated:YES];
    }];

    [[self.homeNavView.locationTitleButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self.navigationController pushViewController:[QWeatherCityManagerViewController new] animated:YES];
    }];

    // 城市切换条：点击切换、点「＋」添加、长按进入管理
    self.cityBar.onSelect = ^(NSInteger index) {
        @strongify(self)
        [self switchToCityIndex:index];
    };
    self.cityBar.onAdd = ^{
        @strongify(self)
        [self.navigationController pushViewController:[QWeatherSearchViewController new] animated:YES];
    };
    self.cityBar.onManage = ^{
        @strongify(self)
        [self.navigationController pushViewController:[QWeatherCityManagerViewController new] animated:YES];
    };
    
    [[self.homeNavView.menuButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self.navigationController pushViewController:[[QWeatherSettingViewController alloc]initWithStyle:UITableViewStyleGrouped] animated:YES];
    }];
    
    if (QWeatherManager.selectLocation) {
        NSString *location = QWeatherManager.selectLocation;
        QWeatherManager.selectLocation = nil;
        [self getDataWithLocation:location isLoaction:YES];
    }else{
        QWeatherPostNotification(KNotificationRefreshHomeData, nil);
        if (![QWeatherTool isLocationAuthorizationStatusDenied]) {
            [self.locationManager startUpdatingLocation];
        }else{
            [self loadDefaultCityIfNeeded];
        }
    }
}

- (void)updateMapManager {
    [AMapLocationManager updatePrivacyShow:AMapPrivacyShowStatusDidShow privacyInfo:AMapPrivacyInfoStatusDidContain];
    [AMapLocationManager updatePrivacyAgree:AMapPrivacyAgreeStatusDidAgree];
}

- (void)amapLocationManager:(AMapLocationManager *)manager didFailWithError:(NSError *)error{
    [self.locationManager stopUpdatingLocation];
    QWeatherLogError(@"%@",error);
    [self loadDefaultCityIfNeeded];
}

/// 定位不可用且没有任何城市时，退回到默认城市，避免首页空白
- (void)loadDefaultCityIfNeeded{
    if (QWeatherManager.collectionDataArray.count > 0) {
        return;
    }
    [self getDataWithLocation:@"北京" isLoaction:NO];
}


- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode{
    [self.locationManager stopUpdatingLocation];
    [self getDataWithLocation:QWeatherStringFormat(@"%.2f,%.2f",location.coordinate.longitude,location.coordinate.latitude) isLoaction:YES];
}

- (void)amapLocationManager:(AMapLocationManager *)manager doRequireLocationAuth:(CLLocationManager *)locationManager
{
    [locationManager requestAlwaysAuthorization];
}

/// 兼容旧入口（定位坐标、历史通知、默认城市）：优先用本地城市库解析，
/// 解析不到才走一次 GEO 反查；两条路径都有失败反馈，不再静默什么都不做。
-(void)getDataWithLocation:(NSString *)location isLoaction:(BOOL)isLoaction{
    if (!QWeatherStrValid(location)) {
        return;
    }
    TBCityCatalog *catalog = [TBCityCatalog sharedCatalog];

    // 1) cid / 中文名能直接命中本地城市库 → 立刻落库，不再多一跳网络请求
    TBCityItem *known = [catalog cityWithID:location] ?: [catalog cityWithName:location];
    if (known) {
        [self addCityWithItem:known isLocation:isLoaction];
        return;
    }

    // 2) 定位经纬度 / 海外城市：走 GEO 反查
    @weakify(self)
    [[[self.weatherRequest.citySearchCommand execute:@{@"location":location}] deliverOnMainThread]
     subscribeNext:^(GeoBaseClass *geo) {
        @strongify(self)
        TBCityItem *item = [[TBCityCatalog sharedCatalog] itemWithLocation:geo.location.firstObject];
        if (!item) {
            QWeatherLogError(@"GEO 无结果：%@", location);
            [self showCityResolveFailureHint];
            return;
        }
        [self addCityWithItem:item isLocation:isLoaction];
    } error:^(NSError *error) {
        @strongify(self)
        QWeatherLogError(@"城市反查失败：%@", error);
        [self showCityResolveFailureHint];
    }];
}

/// 添加城市：先用离线目录信息立即落库，再触发一次串行刷新补天气数据。
/// 网络失败不会让城市消失，这是「添加城市真的可用」的关键。
-(void)addCityWithItem:(TBCityItem *)item isLocation:(BOOL)isLocation{
    if (!item || item.cid.length == 0) {
        return;
    }
    NSInteger existing = [QWeatherManager indexOfCityWithID:item.cid];
    if (existing != NSNotFound && !isLocation) {
        [self switchToCityIndex:existing];
        return;
    }

    QWeatherHomeTabelViewDataModel *placeholder = [QWeatherHomeTabelViewDataModel new];
    placeholder.basic = [item locationValue];
    placeholder.code = @"";
    placeholder.loadState = @"pending";
    placeholder.lastUpdatedAt = 0;

    if (![QWeatherManager addCityModel:placeholder isLocation:isLocation]) {
        [self showCityLimitAlert];
        return;
    }
    NSInteger index = isLocation ? 0 : [QWeatherManager indexOfCityWithID:item.cid];
    QWeatherManager.selectedCityIndex = (index == NSNotFound) ? 0 : index;
    self.errorHintLabel.hidden = YES;
    [self.homeNavView.locationTitleButton setTitle:item.name forState:UIControlStateNormal];
    [self reloadHomeData];
    // 刷新走 upDateHomeDataCommand（逐城市串行、单城失败保留旧数据）
    QWeatherPostNotification(KNotificationRefreshHomeData, nil);
}

-(void)showCityResolveFailureHint{
    self.errorHintLabel.text = @"城市解析失败，请到「添加城市」重试或下拉刷新";
    self.errorHintLabel.hidden = NO;
}

-(void)reloadHomeData{
    NSInteger count = QWeatherManager.collectionDataArray.count;
    if (count == 0) {
        [self.homeNavView setPage:0];
        [self.cityBar reloadWithCityNames:@[] selectedIndex:0];
        [self.weatherCollectionView reloadData];
        self.emptyLabel.hidden = NO;
        self.errorHintLabel.hidden = YES;
        return;
    }
    self.emptyLabel.hidden = YES;
    [self updateErrorHint];

    NSInteger page = MIN(MAX(0, QWeatherManager.selectedCityIndex), count - 1);
    [self.weatherCollectionView reloadData];
    [self.view layoutIfNeeded];
    [self.weatherCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:page inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                animated:NO];
    [self.homeNavView setPage:page];
    [self syncCityBarWithPage:page];
    [self applyBackgroundColor];
}

/// 当前城市数据加载失败时给出可见反馈与重试提示（不弹窗打断操作）
-(void)updateErrorHint{
    NSInteger index = MIN(MAX(0, QWeatherManager.selectedCityIndex),
                          (NSInteger)QWeatherManager.collectionDataArray.count - 1);
    QWeatherHomeTabelViewDataModel *model = QWeatherManager.collectionDataArray[index];
    BOOL failed = QWeatherStrEqual(model.loadState, @"failed");
    self.errorHintLabel.text = failed ? @"天气数据加载失败，下拉可重试" : @"";
    self.errorHintLabel.hidden = !failed;
}

/// 城市切换条与当前页保持同步
-(void)syncCityBarWithPage:(NSInteger)page{
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (QWeatherHomeTabelViewDataModel *model in QWeatherManager.collectionDataArray) {
        [names addObject:model.basic.name ?: @"--"];
    }
    [self.cityBar reloadWithCityNames:names selectedIndex:page];
}

/// 顶部导航区与列表共用天气背景色，避免白底白字看不见城市名
-(void)applyBackgroundColor{
    UIColor *bg = [self.homeNavView.image qmui_averageColor];
    if (!bg) {
        return;
    }
    self.view.backgroundColor = bg;
    self.homeNavView.backgroundColor = bg;
    self.cityBar.backgroundColor = bg;
    self.weatherCollectionView.backgroundColor = bg;
}

/// 点击城市 chip 切换到对应页；数据过期/失败时补一次刷新
-(void)switchToCityIndex:(NSInteger)index{
    NSInteger count = QWeatherManager.collectionDataArray.count;
    if (index < 0 || index >= count) {
        return;
    }
    QWeatherManager.selectedCityIndex = index;
    [self.weatherCollectionView reloadData];
    [self.weatherCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                animated:YES];
    [self.homeNavView setPage:index];
    [self.cityBar updateSelectedIndex:index];
    [self applyBackgroundColor];
    [self updateErrorHint];
    // 30 分钟 TTL：切到过期或上次失败的城市时重新取数，避免「切了城市但内容不变」
    if ([QWeatherManager cityNeedsRefreshAtIndex:index ttl:30 * 60]) {
        QWeatherPostNotification(KNotificationRefreshHomeData, nil);
    }
}

-(void)showCityLimitAlert{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"城市数量已达上限"
                                                                   message:[NSString stringWithFormat:@"最多添加 %ld 个城市，请先删除一个", (long)QWeatherManager.maxCityCount]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
-(void)configUI{
    [self.view addSubview:self.weatherCollectionView];
    [self.view addSubview:self.homeNavView];
    [self.view addSubview:self.cityBar];
    [self.view addSubview:self.emptyLabel];
    [self.view addSubview:self.errorHintLabel];
    [self.homeNavView setPage:self.homeNavView.pageControl.currentPage];
    self.weatherCollectionView.backgroundColor = [self.homeNavView.image qmui_averageColor];
}
-(void)configLayout{
    [self.homeNavView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.view.mas_top);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(44);
    }];
    [self.cityBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.homeNavView.mas_bottom);
        make.height.mas_equalTo(38);
    }];
    [self.weatherCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.top.equalTo(self.cityBar.mas_bottom).offset(2);
    }];
    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.weatherCollectionView);
        make.left.equalTo(self.view).offset(Space_16);
        make.right.equalTo(self.view).offset(-Space_16);
    }];
    [self.errorHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.height.mas_equalTo(32);
    }];
}
#pragma mark - 代理方法 Delegate Methods
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // QMUICollectionViewPagingLayout 会缓存首次算出的 itemSize，
    // 若首次布局时 collectionView 还没被 cityBar 下推，item 高度会大于可视区域，
    // 导致 15 天预报等底部内容被裁掉。这里在尺寸变化后强制刷新一次。
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.weatherCollectionView.collectionViewLayout;
    CGSize size = self.weatherCollectionView.bounds.size;
    if (!layout || size.width <= 0 || size.height <= 0) {
        return;
    }
    if (!CGSizeEqualToSize(layout.itemSize, size)) {
        layout.itemSize = size;
        [layout invalidateLayout];
    }
}

// 设置分区
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
// 每个分区上得元素个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return QWeatherManager.collectionDataArray.count;
}
// 设置cell
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    QWeatherHomeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([QWeatherHomeCollectionViewCell class]) forIndexPath:indexPath];
    cell.scrollView.dataModel = indexPath.row < (NSInteger)QWeatherManager.collectionDataArray.count ? QWeatherManager.collectionDataArray[indexPath.row] : nil;
    return cell;
}

// 设置cell大小 itemSize：可以给每一个cell指定不同的尺寸
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.qmui_width, collectionView.qmui_height);
}
// 设置UIcollectionView整体的内边距（这样item不贴边显示）
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}
// 设置minimumLineSpacing：cell上下之间最小的距离
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}
// 设置minimumInteritemSpacing：cell左右之间最小的距离
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self syncPageWithScrollView:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    [self syncPageWithScrollView:scrollView];
}

/// 分页布局（QMUI scale 样式）下 contentOffset / width 并不等于页码，
/// 用「屏幕中心点落在哪个 cell」来判定当前页，避免切页后高亮/标题错位。
- (void)syncPageWithScrollView:(UIScrollView *)scrollView{
    if (scrollView != self.weatherCollectionView) {
        return;
    }
    NSInteger count = QWeatherManager.collectionDataArray.count;
    if (count == 0) {
        return;
    }
    CGPoint center = CGPointMake(scrollView.contentOffset.x + scrollView.qmui_width / 2.0, scrollView.qmui_height / 2.0);
    NSIndexPath *indexPath = [self.weatherCollectionView indexPathForItemAtPoint:center];
    NSInteger page = indexPath ? indexPath.item : QWeatherManager.selectedCityIndex;
    page = MIN(MAX(0, page), count - 1);
    if (page == QWeatherManager.selectedCityIndex) {
        [self.cityBar updateSelectedIndex:page];
        return;
    }
    QWeatherManager.selectedCityIndex = page;
    [self.homeNavView setPage:page];
    [self.cityBar updateSelectedIndex:page];
    [self applyBackgroundColor];
    [self updateErrorHint];
}

-(UICollectionView *)weatherCollectionView{
    if (!_weatherCollectionView) {
        QMUICollectionViewPagingLayout *flowLayout = [[QMUICollectionViewPagingLayout alloc]initWithStyle:QMUICollectionViewPagingLayoutStyleScale];
        flowLayout.minimumScale = 0.85;
        _weatherCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _weatherCollectionView.dataSource = self;
        _weatherCollectionView.delegate = self;
        _weatherCollectionView.pagingEnabled = YES;
        _weatherCollectionView.showsHorizontalScrollIndicator = NO;
//        [_weatherCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([QWeatherHomeCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:NSStringFromClass([QWeatherHomeCollectionViewCell class])];
        [_weatherCollectionView registerClass:[QWeatherHomeCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([QWeatherHomeCollectionViewCell class])];
        if (@available(iOS 11.0, *)) {
            _weatherCollectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
    }
    return _weatherCollectionView;
}
-(QWeatherHomeNavView *)homeNavView{
    if (!_homeNavView) {
        _homeNavView = [QWeatherHomeNavView new];
    }
    return _homeNavView;
}
-(TBWeatherCityBar *)cityBar{
    if (!_cityBar) {
        _cityBar = [TBWeatherCityBar new];
    }
    return _cityBar;
}
-(QWeatherRequest *)weatherRequest{
    if (!_weatherRequest) {
        _weatherRequest = [QWeatherRequest new];
    }
    return _weatherRequest;
}
-(AMapLocationManager *)locationManager{
    if (!_locationManager) {
        _locationManager = [[AMapLocationManager alloc] init];
        [_locationManager setDelegate:self];
        [_locationManager setPausesLocationUpdatesAutomatically:NO];
        _locationManager.allowsBackgroundLocationUpdates = NO;
    }
    return _locationManager;
}

-(UILabel *)emptyLabel{
    if (!_emptyLabel) {
        _emptyLabel = [UILabel new];
        _emptyLabel.text = @"还没有城市\n点击上方「＋」或城市条添加";
        _emptyLabel.numberOfLines = 0;
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.textColor = [UIColor whiteColor];
        _emptyLabel.font = [UIFont systemFontOfSize:15];
        _emptyLabel.hidden = YES;
    }
    return _emptyLabel;
}

-(UILabel *)errorHintLabel{
    if (!_errorHintLabel) {
        _errorHintLabel = [UILabel new];
        _errorHintLabel.textAlignment = NSTextAlignmentCenter;
        _errorHintLabel.font = [UIFont systemFontOfSize:12];
        _errorHintLabel.textColor = [UIColor whiteColor];
        _errorHintLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
        _errorHintLabel.hidden = YES;
    }
    return _errorHintLabel;
}

@end
