//
//  MovingAnnotationView.m
//  LineAnimation
//
//  Created by 缪雨轩 on 2020/1/3.
//  Copyright © 2020 miaoyuxuan. All rights reserved.
//

#import "MovingAnnotationView.h"

@implementation MovingAnnotationView

- (void)step:(CGFloat)timeDelta {
    
    if(self.isPaused) {
        return;
    }
    
    [super step:timeDelta];
    
    if(self.traveledRouteBlock) {
        self.traveledRouteBlock();
    }
}

@end
