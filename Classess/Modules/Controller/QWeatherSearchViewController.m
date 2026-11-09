//
//  QWeatherSearchViewController.m
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//

#import "QWeatherSearchViewController.h"
#import "QWeatherSearchBarView.h"
#import "QWeatherSearchCell.h"
#import "QWeatherCollectionCityCell.h"
#import "QWeatherRequest.h"
#import "QWeatherDataManager.h"
#import "QWeatherTool.h"
#import <YYText/YYText.h>

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
@property (nonatomic,strong) QWeatherBaseLabel *titleLabel;
@property (nonatomic,strong) QWeatherRequest *weatherRequest;
@property (nonatomic,strong) NSArray<Location *> *searchCityArray;
@property (nonatomic,copy) NSString *searchText;
@property (nonatomic,strong) NSArray *citysArray;
@end

@implementation QWeatherSearchViewController
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}
- (BOOL)shouldHideKeyboardWhenTouchInView:(UIView *)view{
    return YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleView.title = QWeatherLocal(@"hengfengLocalString_36");
    [self configUI];
    [self configLayout];
    [self reload];
}
-(void)configUI{
    [self.view addSubview:self.searchView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.collectionView];
    
    // 输入防抖：300ms 内的连续输入只发一次请求
    [[[[self.searchView.searchTextField rac_textSignal] skip:1] throttle:0.3] subscribeNext:^(NSString * _Nullable x) {
        NSString *keyword = [x qmui_trimAllWhiteSpace];
        self.searchText = keyword;
        if (QWeatherStrValid(keyword)) {
            [[self.weatherRequest.citySearchCommand execute:@{@"location":keyword}] subscribeNext:^(GeoBaseClass  * result) {
                // 结果回来时用户可能已经改了输入，丢弃过期响应
                if (!QWeatherStrEqual(self.searchText, keyword)) {
                    return;
                }
                self.searchCityArray = result.location.count > 0 ? result.location : @[];
                [self reload];
            } error:^(NSError * _Nullable error) {
                QWeatherLogError(@"%@", error);
                if (!QWeatherStrEqual(self.searchText, keyword)) {
                    return;
                }
                self.searchCityArray = @[];
                [self reload];
            }];
        }else{
            self.searchCityArray = @[];
            [self reload];
        }
    }];
}
-(void)reload{
    // 没有搜索结果时展示热门城市，方便直接添加
    self.collectionView.hidden = self.searchCityArray.count > 0;
    self.tableView.backgroundColor = self.searchCityArray.count==0?QWeatherColor_ECECEC:QWeatherColor_FAFAFA;
    [self.tableView reloadData];
    [self updateLayout];
}
-(void)updateLayout{
    if (self.searchCityArray.count>0) {
        [self.titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
    }else{
        [self.titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(50);
        }];
    }
    [self.view layoutIfNeeded];
}
-(void)configLayout{
    [self.searchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuide);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(56);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.searchView.mas_bottom);
        make.left.mas_equalTo(Space_16);
        make.height.mas_equalTo(50);
    }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.top.equalTo(self.titleLabel.mas_bottom);
    }];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tableView);
    }];
}

#pragma mark UITableViewDelegate,UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.searchCityArray.count>0) {
        return self.searchCityArray.count;
    }else{
        return QWeatherManager.collectionDataArray.count;
    }
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    QWeatherSearchCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([QWeatherSearchCell class])];
    if (self.searchCityArray.count>0) {
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc]initWithString:[self cityTitleWithSearchModel:self.searchCityArray[indexPath.row]]];
        text.yy_color = QWeatherColor_7A7A7A;
        [text yy_setColor:QWeatherColor_ED802D range:[[self cityTitleWithSearchModel:self.searchCityArray[indexPath.row]] rangeOfString:self.searchText]];
        cell.titleLabel.attributedText = text;
    }else{
        cell.titleLabel.text = [self cityTitleWithModel:QWeatherManager.collectionDataArray[indexPath.row].basic];
    }
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.isSelectLocatin) {
        if (self.searchCityArray.count > 0) {
            QWeatherManager.selectLocation = self.searchCityArray[indexPath.row].cid;
        }else if (indexPath.row < (NSInteger)QWeatherManager.collectionDataArray.count) {
            QWeatherManager.selectLocation = QWeatherManager.collectionDataArray[indexPath.row].basic.name;
        }else{
            return;
        }
        QWeatherPostNotification(KNotificationRestRootVC, nil);
    }else{
        if (self.searchCityArray.count>0) {
            QWeatherPostNotification(KNotificationRefreshCity,self.searchCityArray[indexPath.row].cid);
        }else{
            QWeatherManager.selectedCityIndex = indexPath.row;
            QWeatherPostNotification(KNotificationRefreshHomeData, nil);
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}
-(NSString *)cityTitleWithSearchModel:(Location *)model{
    NSMutableArray *array = [NSMutableArray array];
    if (QWeatherStrValid(model.name)) {
        [array addObject:model.name];
    }
    if (QWeatherStrValid(model.adm2)) {
        [array addObject:model.adm2];
    }
    if (QWeatherStrValid(model.adm1)) {
        [array addObject:model.adm1];
    }
    if (QWeatherStrValid(model.country)) {
        [array addObject:model.country];
    }
    NSMutableArray *titleArray = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [titleArray addObject:[obj capitalizedString]];
    }];
    return [titleArray componentsJoinedByString:@","];
}
-(NSString *)cityTitleWithModel:(Location *)model{
    NSMutableArray *array = [NSMutableArray array];
    if (QWeatherStrValid(model.name)) {
        [array addObject:model.name];
    }
    if (QWeatherStrValid(model.adm2)) {
        [array addObject:model.adm2];
    }
    if (QWeatherStrValid(model.adm1)) {
        [array addObject:model.adm1];
    }
    if (QWeatherStrValid(model.country)) {
        [array addObject:model.country];
    }
    NSMutableArray *titleArray = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [titleArray addObject:[obj capitalizedString]];
    }];
    return [titleArray componentsJoinedByString:@","];
}
#pragma mark ---- UICollectionView
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.citysArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    QWeatherCollectionCityCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([QWeatherCollectionCityCell class]) forIndexPath:indexPath];
    cell.titleLabel.text = self.citysArray[indexPath.row];
    return cell;
}


#pragma mark ---- UICollectionViewDelegateFlowLayout

//动态设置每个Item的尺寸大小

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return (CGSize){(collectionView.qmui_width-Space_16*4)/3,40};
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(Space_16, Space_16, 0, Space_16);
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return Space_16;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}


// 选中热门城市
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isSelectLocatin) {
        QWeatherManager.selectLocation = self.citysArray[indexPath.row];
        QWeatherPostNotification(KNotificationRestRootVC, nil);
        return;
    }
    QWeatherPostNotification(KNotificationRefreshCity, self.citysArray[indexPath.row]);
    [self.navigationController popViewControllerAnimated:YES];
}
-(UICollectionView *)collectionView{
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:[UICollectionViewFlowLayout new]];
        [_collectionView registerClass:[QWeatherCollectionCityCell class] forCellWithReuseIdentifier:NSStringFromClass([QWeatherCollectionCityCell class])];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = QWeatherColor_ECECEC;
        _collectionView.hidden = !self.isSelectLocatin;
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
-(NSArray *)citysArray{
    if (!_citysArray) {
        _citysArray =   @[
                          @"洛杉矶",
                          @"北京",
                          @"上海",
                          @"深圳",
                          @"伦敦",
                          @"杭州",
                          @"重庆",
                          @"武汉",
                          @"西安",
                          @"纽约",
                          @"巴黎",
                          @"莫斯科",
                          ];
    }
    return _citysArray;
}
-(QWeatherBaseLabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [QWeatherBaseLabel new];
        _titleLabel.hefengFontSize = 12;
        _titleLabel.textColor = QWeatherColor_7A7A7A;
        _titleLabel.hefengLocalString = self.isSelectLocatin? @"hengfengLocalString_50":@"hengfengLocalString_45";
    }
    return _titleLabel;
}

@end
