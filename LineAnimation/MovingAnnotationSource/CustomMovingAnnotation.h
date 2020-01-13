//
//  CustomMovingAnnotation.h
//  LineAnimation
//
//  Created by 缪雨轩 on 2020/1/3.
//  Copyright © 2020 miaoyuxuan. All rights reserved.
//

#import "MovingAnnotationView.h"
#import "MovingAnnotationView.h"
NS_ASSUME_NONNULL_BEGIN

typedef void(^CustomMovingAnnotationCallback)();

@interface CustomMovingAnnotation : MovingAnnotationView

@property (nonatomic, copy) CustomMovingAnnotationCallback stepCallback;

- (CLLocationDirection)rotateDegree;

@end

NS_ASSUME_NONNULL_END
