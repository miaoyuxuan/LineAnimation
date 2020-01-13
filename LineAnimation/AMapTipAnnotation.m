//
//  AMapTipAnnotation.m
//  officialDemo2D
//
//  Created by PC on 15/8/25.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import "AMapTipAnnotation.h"

@interface AMapTipAnnotation()

@property (nonatomic, readwrite, strong) AMapTip *tip;

@end


@implementation AMapTipAnnotation

- (NSString *)title
{
    return self.tip.name;
}


- (NSString *)subtitle
{
    return self.tip.address;
}

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(self.tip.location.latitude, self.tip.location.longitude);
}

- (instancetype)initWithMapTip:(AMapTip *)tip
{
    self = [super init];
    if (self)
    {
        self.tip = tip;
    }
    return self;
}

@end
