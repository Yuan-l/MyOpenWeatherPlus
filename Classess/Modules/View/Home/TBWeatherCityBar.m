//
//  TBWeatherCityBar.m
//  MyOpenWeatherPlus
//

#import "TBWeatherCityBar.h"
#import "TBWeatherLayout.h"

#import "CommonMacros.h"
#import "FontAndColorMacros.h"
#import "UtilsMacros.h"
#import <Masonry/Masonry.h>
#import <QMUIKit/QMUIKit.h>

@interface TBWeatherCityBar ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *cityButtons;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, assign) NSInteger selectedIndex;
@end

@implementation TBWeatherCityBar

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configUI];
    }
    return self;
}

- (void)configUI {
    self.backgroundColor = [UIColor clearColor];

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.alwaysBounceHorizontal = YES;
    [self addSubview:_scrollView];

    _stackView = [[UIStackView alloc] init];
    _stackView.axis = UILayoutConstraintAxisHorizontal;
    _stackView.alignment = UIStackViewAlignmentCenter;
    _stackView.spacing = 8;
    [_scrollView addSubview:_stackView];

    _cityButtons = [NSMutableArray array];

    _addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_addButton setTitle:@"＋" forState:UIControlStateNormal];
    _addButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [_addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _addButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18];
    _addButton.layer.cornerRadius = 14;
    _addButton.contentEdgeInsets = UIEdgeInsetsMake(4, 12, 4, 12);
    [_addButton addTarget:self action:@selector(addTapped) forControlEvents:UIControlEventTouchUpInside];
    _addButton.accessibilityLabel = @"添加城市";

    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [_stackView addArrangedSubview:_addButton];
}

- (void)reloadWithCityNames:(NSArray<NSString *> *)names selectedIndex:(NSInteger)selectedIndex {
    for (UIButton *button in self.cityButtons) {
        [self.stackView removeArrangedSubview:button];
        [button removeFromSuperview];
    }
    [self.cityButtons removeAllObjects];

    if (!names.count) {
        self.selectedIndex = 0;
        [self setNeedsLayout];
        return;
    }

    NSInteger insertIndex = 0;
    for (NSString *name in names) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:(name.length ? name : @"--") forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        button.layer.cornerRadius = 14;
        button.contentEdgeInsets = UIEdgeInsetsMake(4, 14, 4, 14);
        button.tag = insertIndex;
        [button addTarget:self action:@selector(cityTapped:) forControlEvents:UIControlEventTouchUpInside];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(cityLongPressed:)];
        [button addGestureRecognizer:longPress];

        [self.stackView insertArrangedSubview:button atIndex:insertIndex];
        [self.cityButtons addObject:button];
        insertIndex++;
    }

    [self updateSelectedIndex:selectedIndex];
}

- (void)updateSelectedIndex:(NSInteger)selectedIndex {
    if (self.cityButtons.count == 0) {
        return;
    }
    self.selectedIndex = MAX(0, MIN(selectedIndex, (NSInteger)self.cityButtons.count - 1));
    for (UIButton *button in self.cityButtons) {
        BOOL on = (button.tag == self.selectedIndex);
        button.backgroundColor = on ? [[UIColor whiteColor] colorWithAlphaComponent:0.92]
                                    : [[UIColor whiteColor] colorWithAlphaComponent:0.18];
        [button setTitleColor:on ? QWeatherColor_212121 : [UIColor whiteColor] forState:UIControlStateNormal];
    }
    UIButton *selected = self.cityButtons[self.selectedIndex];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    CGRect rect = [selected convertRect:selected.bounds toView:self.scrollView];
    [self.scrollView scrollRectToVisible:CGRectInset(rect, -20, 0) animated:YES];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = [self.stackView systemLayoutSizeFittingSize:CGSizeMake(CGFLOAT_MAX, self.bounds.size.height)];
    self.stackView.frame = CGRectMake(16, 0, size.width, self.bounds.size.height);
    self.scrollView.contentSize = CGSizeMake(size.width + 32, self.bounds.size.height);
}

- (void)cityTapped:(UIButton *)sender {
    if (sender.tag == self.selectedIndex) {
        return;
    }
    NSInteger index = sender.tag;
    [self updateSelectedIndex:index];
    if (self.onSelect) {
        self.onSelect(index);
    }
}

- (void)cityLongPressed:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [feedback impactOccurred];
    if (self.onManage) {
        self.onManage();
    }
}

- (void)addTapped {
    if (self.onAdd) {
        self.onAdd();
    }
}

@end
