//
//  QWeatherCityManagerViewController.m
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//

#import "QWeatherCityManagerViewController.h"
#import "QWeatherCityManagerCell.h"
#import "QWeatherDataManager.h"
#import "QWeatherTool.h"

#import "CommonMacros.h"
#import "FontAndColorMacros.h"
#import "UtilsMacros.h"
#import <Masonry/Masonry.h>
#import <QMUIKit/QMUIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface QWeatherCityManagerViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UILabel *emptyLabel;
@end

@implementation QWeatherCityManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleView.title = QWeatherLocal(@"hengfengLocalString_14");

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"排序"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(toggleEditing)];

    [self configUI];
    [self configLayout];
    [self refreshEmptyState];
}

-(void)configUI{
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.emptyLabel];
}
-(void)configLayout{
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.top.equalTo(self.mas_topLayoutGuide).offset(Space_16);
    }];
    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
}

-(void)refreshEmptyState{
    self.emptyLabel.hidden = QWeatherManager.collectionDataArray.count > 0;
}

#pragma mark - Actions

-(void)toggleEditing{
    BOOL editing = !self.tableView.editing;
    [self.tableView setEditing:editing animated:YES];
    self.navigationItem.rightBarButtonItem.title = editing ? @"完成" : @"排序";
}

-(void)showKeepOneAlert{
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"至少保留一个城市"
                                            message:@"删除后首页将没有内容可展示"
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)deleteCityAtIndex:(NSInteger)index{
    if (index < 0 || index >= (NSInteger)QWeatherManager.collectionDataArray.count) {
        return;
    }
    if (QWeatherManager.collectionDataArray.count <= 1) {
        [self showKeepOneAlert];
        return;
    }
    [QWeatherManager delCollectionDataArrayWithIndex:index];
    [self.tableView reloadData];
    [self refreshEmptyState];
    QWeatherPostNotification(KNotificationRefreshHomeData, nil);
}

#pragma mark - UITableViewDataSource / Delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return QWeatherManager.collectionDataArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    QWeatherCityManagerCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([QWeatherCityManagerCell class])];
    QWeatherHomeTabelViewDataModel *model = QWeatherManager.collectionDataArray[indexPath.row];
    cell.titleLabel.text = model.basic.name;
    cell.accessoryType = indexPath.row == QWeatherManager.selectedCityIndex
        ? UITableViewCellAccessoryCheckmark
        : UITableViewCellAccessoryNone;
    cell.tintColor = QWeatherColor_ED802D;

    [[[cell.delButton rac_signalForControlEvents:UIControlEventTouchUpInside] takeUntil:cell.rac_prepareForReuseSignal] subscribeNext:^(__kindof UIControl * _Nullable x) {
        [self deleteCityAtIndex:indexPath.row];
    }];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    QWeatherManager.selectedCityIndex = indexPath.row;
    QWeatherPostNotification(KNotificationRefreshHomeData, nil);
    [self.navigationController popViewControllerAnimated:YES];
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleNone;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
    BOOL moved = [QWeatherManager moveCityFromIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
    if (!moved) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [tableView reloadData];
    });
    QWeatherPostNotification(KNotificationRefreshHomeData, nil);
}

#pragma mark - Lazy

-(UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_tableView registerClass:[QWeatherCityManagerCell class] forCellReuseIdentifier:NSStringFromClass([QWeatherCityManagerCell class])];
    }
    return _tableView;
}

-(UILabel *)emptyLabel{
    if (!_emptyLabel) {
        _emptyLabel = [UILabel new];
        _emptyLabel.text = @"还没有城市，去搜索页添加一个吧";
        _emptyLabel.font = [QWeatherTool getFontWithFontSize:QWeatherFontSize_14];
        _emptyLabel.textColor = QWeatherColor_7A7A7A;
        _emptyLabel.hidden = YES;
    }
    return _emptyLabel;
}

@end
