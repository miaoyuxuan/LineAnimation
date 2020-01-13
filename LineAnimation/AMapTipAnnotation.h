//
//  AMapTipAnnotation.h
//  officialDemo2D
//
//  Created by PC on 15/8/25.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AMapSearchKit/AMapCommonObj.h>
#import <MAMapKit/MAMapKit.h>

@interface AMapTipAnnotation : NSObject <MAAnnotation>

- (instancetype)initWithMapTip:(AMapTip *)tip;

@property (nonatomic, readonly, strong) AMapTip *tip;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

/*!
 @brief 获取annotation标题
 @return 返回annotation的标题信息
 */
- (NSString *)title;

/*!
 @brief 获取annotation副标题
 @return 返回annotation的副标题信息
 */
- (NSString *)subtitle;

@end
