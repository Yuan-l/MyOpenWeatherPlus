//
//  TBWeatherSunMoonView.m
//  OpenWeatherPlus
//
//  日月信息区块：日出日落（sunMoonModel 优先，daily15.firstObject 兜底）、月出月落、当前月相名
//

#import "TBWeatherSunMoonView.h"
#import "QWeatherBaseLabel.h"

#import "CommonMacros.h"
#import "FontAndColorMacros.h"
#import "UtilsMacros.h"
#import <Masonry/Masonry.h>
#import <QMUIKit/QMUIKit.h>

@interface TBWeatherSunMoonView()
@property (nonatomic,strong) QWeatherBaseLabel *sunriseTitleLabel;
@property (nonatomic,strong) QWeatherBaseLabel *sunriseValueLabel;
@property (nonatomic,strong) QWeatherBaseLabel *sunsetTitleLabel;
@property (nonatomic,strong) QWeatherBaseLabel *sunsetValueLabel;
@property (nonatomic,strong) QWeatherBaseLabel *moonriseTitleLabel;
@property (nonatomic,strong) QWeatherBaseLabel *moonriseValueLabel;
@property (nonatomic,strong) QWeatherBaseLabel *moonsetTitleLabel;
@property (nonatomic,strong) QWeatherBaseLabel *moonsetValueLabel;
@property (nonatomic,strong) QWeatherBaseLabel *moonPhaseLabel;
@end

@implementation TBWeatherSunMoonView
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configUI];
        self.backgroundColor = QWeatherColor_F0F0F0;
    }
    return self;
}
-(void)configUI{
    self.sunriseTitleLabel = [QWeatherBaseLabel new];
    self.sunriseTitleLabel.textColor = QWeatherColor_A4A4A4;
    self.sunriseTitleLabel.text = @"🌅 日出";
    [self addSubview:self.sunriseTitleLabel];

    self.sunriseValueLabel = [QWeatherBaseLabel new];
    self.sunriseValueLabel.textColor = QWeatherColor_212121;
    [self addSubview:self.sunriseValueLabel];

    self.sunsetTitleLabel = [QWeatherBaseLabel new];
    self.sunsetTitleLabel.textColor = QWeatherColor_A4A4A4;
    self.sunsetTitleLabel.text = @"🌇 日落";
    [self addSubview:self.sunsetTitleLabel];

    self.sunsetValueLabel = [QWeatherBaseLabel new];
    self.sunsetValueLabel.textColor = QWeatherColor_212121;
    [self addSubview:self.sunsetValueLabel];

    self.moonriseTitleLabel = [QWeatherBaseLabel new];
    self.moonriseTitleLabel.textColor = QWeatherColor_A4A4A4;
    self.moonriseTitleLabel.text = @"🌙 月出";
    [self addSubview:self.moonriseTitleLabel];

    self.moonriseValueLabel = [QWeatherBaseLabel new];
    self.moonriseValueLabel.textColor = QWeatherColor_212121;
    [self addSubview:self.moonriseValueLabel];

    self.moonsetTitleLabel = [QWeatherBaseLabel new];
    self.moonsetTitleLabel.textColor = QWeatherColor_A4A4A4;
    self.moonsetTitleLabel.text = @"🌌 月落";
    [self addSubview:self.moonsetTitleLabel];

    self.moonsetValueLabel = [QWeatherBaseLabel new];
    self.moonsetValueLabel.textColor = QWeatherColor_212121;
    [self addSubview:self.moonsetValueLabel];

    self.moonPhaseLabel = [QWeatherBaseLabel new];
    self.moonPhaseLabel.textColor = QWeatherColor_4A4A4A;
    [self addSubview:self.moonPhaseLabel];
}
-(void)layoutSubviews{
    [super layoutSubviews];
    //两列布局：左列日出/月出，右列日落/月落
    [self.sunriseTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(Space_16);
        make.top.mas_equalTo(Space_16);
        make.height.mas_equalTo(20);
    }];
    [self.sunriseValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.sunriseTitleLabel);
        make.top.equalTo(self.sunriseTitleLabel.mas_bottom).offset(4);
        make.height.mas_equalTo(24);
    }];
    [self.sunsetTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_centerX).offset(Space_16);
        make.top.equalTo(self.sunriseTitleLabel);
        make.height.mas_equalTo(20);
    }];
    [self.sunsetValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.sunsetTitleLabel);
        make.top.equalTo(self.sunriseValueLabel);
        make.height.mas_equalTo(24);
    }];
    [self.moonriseTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.sunriseTitleLabel);
        make.top.equalTo(self.sunriseValueLabel.mas_bottom).offset(Space_16);
        make.height.mas_equalTo(20);
    }];
    [self.moonriseValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.sunriseTitleLabel);
        make.top.equalTo(self.moonriseTitleLabel.mas_bottom).offset(4);
        make.height.mas_equalTo(24);
    }];
    [self.moonsetTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.sunsetTitleLabel);
        make.top.equalTo(self.moonriseTitleLabel);
        make.height.mas_equalTo(20);
    }];
    [self.moonsetValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.sunsetTitleLabel);
        make.top.equalTo(self.moonriseValueLabel);
        make.height.mas_equalTo(24);
    }];
    [self.moonPhaseLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(Space_16);
        make.right.mas_equalTo(-Space_16);
        make.top.equalTo(self.moonriseValueLabel.mas_bottom).offset(Space_16);
        make.height.mas_equalTo(20);
    }];
}
-(void)reloadViewWithModel:(QWeatherHomeTabelViewDataModel *)model{
    NSString *sunrise = nil;
    NSString *sunset = nil;
    NSString *moonrise = nil;
    NSString *moonset = nil;
    NSString *moonPhaseName = nil;

    SunMoonBaseModel *sunMoon = model.sunMoonModel;
    if (sunMoon && QWeatherStrValid(sunMoon.sunrise)) {
        sunrise = sunMoon.sunrise;
        sunset = sunMoon.sunset;
        moonrise = sunMoon.moonrise;
        moonset = sunMoon.moonset;
        if (QWeatherValidArray(sunMoon.moonPhases)) {
            moonPhaseName = sunMoon.moonPhases.firstObject.name;
        }
    }
    //兜底：取 15 天预报第一天的日月数据
    if (!sunrise && QWeatherValidArray(model.daily15)) {
        Daily *today = model.daily15.firstObject;
        sunrise = today.sunrise;
        sunset = today.sunset;
        moonrise = today.moonrise;
        moonset = today.moonset;
        moonPhaseName = today.moonPhase;
    }

    self.sunriseValueLabel.text = QWeatherStrValid(sunrise) ? sunrise : @"--";
    self.sunsetValueLabel.text = QWeatherStrValid(sunset) ? sunset : @"--";
    self.moonriseValueLabel.text = QWeatherStrValid(moonrise) ? moonrise : @"--";
    self.moonsetValueLabel.text = QWeatherStrValid(moonset) ? moonset : @"--";
    self.moonPhaseLabel.text = QWeatherStrValid(moonPhaseName) ? [NSString stringWithFormat:@"当前月相：%@", moonPhaseName] : @"当前月相：--";
}
@end
