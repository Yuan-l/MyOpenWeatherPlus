//
//  QWeatherBaseView.m
//  OpenWeatherPlus
//
//  Created by he on 2019/3/29.
//  Copyright © 2019 QWeather. All rights reserved.
//

#import "QWeatherBaseView.h"
#import "FontAndColorMacros.h"

@implementation QWeatherBaseView

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = QWeatherColor_F7F8FA;
    }
    return self;
}
-(void)reloadViewWithModel:(QWeatherHomeTabelViewDataModel *)model{
    
}
@end
