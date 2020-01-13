//
//  CalculateDistance.h
//  LineAnimation
//
//  Created by 缪雨轩 on 2020/1/9.
//  Copyright © 2020 miaoyuxuan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CalculateDistance : NSObject

+ (float)getDistance:(float)lat1 lng1:(float)lng1 lat2:(float)lat2 lng2:(float)lng2;

@end

NS_ASSUME_NONNULL_END
