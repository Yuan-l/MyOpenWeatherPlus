//
//  TBWeatherIndicesView.m
//  OpenWeatherPlus
//
//  生活指数区块：穿衣/紫外线/洗车/运动/舒适度/感冒，每行 icon + name + level + text
//

#import "TBWeatherIndicesView.h"
#import "QWeatherBaseLabel.h"

#import "CommonMacros.h"
#import "FontAndColorMacros.h"
#import "UtilsMacros.h"
#import <Masonry/Masonry.h>
#import <QMUIKit/QMUIKit.h>

@interface TBWeatherIndicesRowView : QWeatherBaseView
@property (nonatomic,strong) QWeatherBaseLabel *iconLabel;
@property (nonatomic,strong) QWeatherBaseLabel *nameLabel;
@property (nonatomic,strong) QWeatherBaseLabel *levelLabel;
@property (nonatomic,strong) QWeatherBaseLabel *textLabel;
@end

@implementation TBWeatherIndicesRowView
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configUI];
        self.backgroundColor = QWeatherColor_F0F0F0;
    }
    return self;
}
-(void)configUI{
    self.iconLabel = [QWeatherBaseLabel new];
    self.iconLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.iconLabel];

    self.nameLabel = [QWeatherBaseLabel new];
    self.nameLabel.textColor = QWeatherColor_212121;
    [self addSubview:self.nameLabel];

    self.levelLabel = [QWeatherBaseLabel new];
    self.levelLabel.textColor = QWeatherColor_4A4A4A;
    [self addSubview:self.levelLabel];

    self.textLabel = [QWeatherBaseLabel new];
    self.textLabel.textColor = QWeatherColor_7A7A7A;
    self.textLabel.numberOfLines = 2;
    [self addSubview:self.textLabel];
}
-(void)layoutSubviews{
    [super layoutSubviews];
    [self.iconLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(Space_16);
        make.top.mas_equalTo(8);
        make.width.mas_equalTo(30);
        make.height.mas_equalTo(20);
    }];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.iconLabel.mas_right).offset(Space_16);
        make.top.mas_equalTo(8);
        make.right.equalTo(self.levelLabel.mas_left).offset(-Space_16);
    }];
    [self.levelLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-Space_16);
        make.top.mas_equalTo(8);
        make.height.mas_equalTo(20);
    }];
    [self.textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.nameLabel.mas_left);
        make.right.mas_equalTo(-Space_16);
        make.top.equalTo(self.nameLabel.mas_bottom).offset(4);
        make.height.mas_greaterThanOrEqualTo(20);
    }];}
@end

@interface TBWeatherIndicesView()
@property (nonatomic,strong) NSMutableArray<TBWeatherIndicesRowView*> *rowViewArray;
@property (nonatomic,assign) BOOL didDistribute;
@end

@implementation TBWeatherIndicesView
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.rowViewArray = [NSMutableArray array];
        self.backgroundColor = QWeatherColor_F0F0F0;
    }
    return self;
}
-(void)layoutSubviews{
    [super layoutSubviews];
    // 生活指数为可选数据：拉取失败时数组为空，Masonry 分布约束会直接抛异常
    if (self.rowViewArray.count == 0 || self.didDistribute) { return; }
    self.didDistribute = YES;
    [self.rowViewArray mas_distributeViewsAlongAxis:MASAxisTypeVertical withFixedSpacing:16 leadSpacing:Space_16 tailSpacing:Space_16];
    [self.rowViewArray mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
    }];
}
-(void)reloadViewWithModel:(QWeatherHomeTabelViewDataModel *)model{
    [self.rowViewArray enumerateObjectsUsingBlock:^(TBWeatherIndicesRowView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [self.rowViewArray removeAllObjects];
    self.didDistribute = NO;

    if (!QWeatherValidArray(model.indicesModel.daily)) {
        return;
    }

    //穿衣/紫外线/洗车/运动/舒适度/感冒 对应 type：3(uv)/1(drsg)/2(cw)/5(spt)/8(comf)/9(flu)
    NSDictionary<NSString *, NSString *> *iconMap = @{
        @"1": @"👕",//穿衣
        @"2": @"🚗",//洗车
        @"3": @"☀️",//紫外线
        @"5": @"🏃",//运动
        @"8": @"😌",//舒适度
        @"9": @"🤧",//感冒
    };

    [model.indicesModel.daily enumerateObjectsUsingBlock:^(IndicesDaily * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TBWeatherIndicesRowView *row = [TBWeatherIndicesRowView new];
        row.iconLabel.hefengFontSize = QWeatherFontSize_14;
        row.nameLabel.hefengFontSize = QWeatherFontSize_14;
        row.levelLabel.hefengFontSize = QWeatherFontSize_12;
        row.textLabel.hefengFontSize = QWeatherFontSize_12;
        [self addSubview:row];
        [self.rowViewArray addObject:row];

        row.iconLabel.text = iconMap[obj.type] ?: @"📋";
        row.nameLabel.text = obj.name;
        row.levelLabel.text = obj.level;
        row.textLabel.text = obj.text;
    }];
    [self setNeedsLayout];
}
@end
