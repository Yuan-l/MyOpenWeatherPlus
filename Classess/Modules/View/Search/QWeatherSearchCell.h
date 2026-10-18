//
//  QWeatherSearchCell.h
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//
#import "QWeatherBaseLabel.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QWeatherSearchCell : UITableViewCell
@property (nonatomic,strong) UIView *line;
@property (nonatomic,strong) QWeatherBaseLabel *titleLabel;
@end

NS_ASSUME_NONNULL_END
