//
//  CalculateDistance.m
//  LineAnimation
//
//  Created by 缪雨轩 on 2020/1/9.
//  Copyright © 2020 miaoyuxuan. All rights reserved.
//

#import "CalculateDistance.h"

@implementation CalculateDistance

+ (float)getDistance:(float)lat1 lng1:(float)lng1 lat2:(float)lat2 lng2:(float)lng2 {

//地球半径

int R = 6378137;

//将角度转为弧度

float radLat1 = [self radians:lat1];

float radLat2 = [self radians:lat2];

float radLng1 = [self radians:lng1];

float radLng2 = [self radians:lng2];

//结果

float s = acos(cos(radLat1)*cos(radLat2)*cos(radLng1-radLng2)+sin(radLat1)*sin(radLat2))*R;

//精度

s = round(s* 10000)/10000;

return  round(s) / 1000;

}

+ (float)radians:(float)degrees {

return (degrees*3.14159265)/180.0;

}

@end
