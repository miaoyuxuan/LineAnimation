//
//  MovingAnnotationView.h
//  LineAnimation
//
//  Created by 缪雨轩 on 2020/1/3.
//  Copyright © 2020 miaoyuxuan. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^TraveledRouteBlock)();

@interface MovingAnnotationView : MAAnimatedAnnotation

@property (nonatomic, assign) BOOL isPaused; //默认NO

@property (nonatomic,copy)  TraveledRouteBlock traveledRouteBlock;
@end

NS_ASSUME_NONNULL_END
