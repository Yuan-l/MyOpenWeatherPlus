//
//  QWeatherCityManagerCell.h
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QWeatherBaseLabel.h"

NS_ASSUME_NONNULL_BEGIN

@interface QWeatherCityManagerCell : UITableViewCell
@property (nonatomic,strong) UIView *line;
@property (nonatomic,strong) QWeatherBaseLabel *titleLabel;
@property (nonatomic,strong) UIButton *delButton;
@end

NS_ASSUME_NONNULL_END
