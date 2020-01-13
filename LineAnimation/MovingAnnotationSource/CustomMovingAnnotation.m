//
//  CustomMovingAnnotation.m
//  LineAnimation
//
//  Created by 缪雨轩 on 2020/1/3.
//  Copyright © 2020 miaoyuxuan. All rights reserved.
//

#import "CustomMovingAnnotation.h"

@implementation CustomMovingAnnotation

- (void)step:(CGFloat)timeDelta {
    [super step:timeDelta];
    
    if(self.stepCallback) {
        self.stepCallback();
    }
}

- (CLLocationDirection)rotateDegree {
    return 0;
}

@end
