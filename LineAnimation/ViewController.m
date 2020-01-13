//
//  ViewController.m
//  LineAnimation
//
//  Created by 缪雨轩 on 2020/1/3.
//  Copyright © 2020 miaoyuxuan. All rights reserved.
//

#import "ViewController.h"

static CLLocationCoordinate2D s_coords[] =
{
    {31.4921890000,120.3743810000},
    {31.4919060000,120.3746170000},
    {31.4917500000,120.3746820000},
    {31.4915950000,120.3748640000},
    {31.4914580000,120.3750030000},
    {31.4911650000,120.3751750000},
    {31.4909180000,120.3753040000},
    {31.4906250000,120.3754860000},
    {31.4904510000,120.3755930000},
    {31.4902500000,120.3757120000},
    {31.4900940000,120.3758510000},
    {31.4898560000,120.3760010000},
    {31.4896000000,120.3759260000},
    {31.4893810000,120.3760550000},
    {31.4891430000,120.3761620000},
    {31.4889140000,120.3763230000},
    {31.4886760000,120.3764300000},
    {31.4890150000,120.3771280000},
    {31.4893620000,120.3778360000},
    {31.4896830000,120.3782860000},
    {31.4900490000,120.3787800000},
    {31.4904790000,120.3794450000},
    {31.4909180000,120.3800460000},
    {31.4914210000,120.3806150000},
    {31.4917960000,120.3811190000},
    {31.4922530000,120.3815800000},
    {31.4926560000,120.3822350000},
    {31.4931960000,120.3828520000},
    {31.4937540000,120.3823260000},
    {31.4943120000,120.3817150000},
    {31.4947880000,120.3811140000},
    {31.4952820000,120.3804490000},
    {31.4959320000,120.3795640000},
    {31.4963980000,120.3790380000},
    {31.4966680000,120.3787270000},
    {31.4964300000,120.3783860000},
    {31.4961010000,120.3781020000},
    {31.4957390000,120.3777370000},
    {31.4954240000,120.3774150000},
    {31.4950810000,120.3770770000},
    {31.4946330000,120.3766480000},
    {31.4942250000,120.3762670000},
    {31.4938780000,120.3758760000},
    {31.4931180000,120.3752430000},
    {31.4926980000,120.3747710000},
    {31.4922860000,120.3743950000}
};

@interface ViewController ()<MAMapViewDelegate>

@property (nonatomic, strong) MAMapView *mapView;

///车头方向跟随转动
@property (nonatomic, strong) MovingAnnotationView *car1;
///车头方向不跟随转动
@property (nonatomic, strong) CustomMovingAnnotation *car2;

///全轨迹overlay
@property (nonatomic, strong) MAPolyline *fullTraceLine;
///走过轨迹的overlay
@property (nonatomic, strong) MAPolyline *passedTraceLine;
@property (nonatomic, assign) int passedTraceCoordIndex;
@property (nonatomic, assign) int car1passedTraceCoordIndex;
@property (nonatomic, strong) NSArray *distanceArray;
@property (nonatomic, assign) double sumDistance;

@property (nonatomic, weak) MAAnnotationView *car1View;
@property (nonatomic, weak) MAAnnotationView *car2View;

@property (nonatomic, strong) NSMutableArray *carsArray;

@property (nonatomic, strong) UIButton *pauseBtn;

@property (nonatomic, strong) UILabel *distanceText;

@property (nonatomic, assign) NSInteger *driveCount;

@property (nonatomic, strong) NSMutableArray *coordArray;

@property (nonatomic, strong) NSTimer *distanceTimer;

@property(nonatomic,assign) double runningTime;

@end

@implementation ViewController

#pragma mark - Map Delegate
- (void)mapInitComplete:(MAMapView *)mapView {
    [self initRoute];
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if (annotation == self.car1 || [self.carsArray containsObject:annotation]) {
        NSString *pointReuseIndetifier = @"pointReuseIndetifier1";
        
        MAAnnotationView *annotationView = (MAAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
        if(!annotationView) {
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndetifier];
             
            annotationView.canShowCallout = YES;
            
            UIImage *imge  =  [UIImage imageNamed:@"car1"];
            annotationView.image =  imge;
            
            if(annotation == self.car1) {
                self.car1View = annotationView;
            }
        }

        return annotationView;
    } else if(annotation == self.car2) {
        NSString *pointReuseIndetifier = @"pointReuseIndetifier2";
        
        MAAnnotationView *annotationView = (MAAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
        if(!annotationView) {
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndetifier];
            
            annotationView.canShowCallout = YES;
            
            UIImage *imge  =  [UIImage imageNamed:@"car2"];
            annotationView.image =  imge;
            
            self.car2View = annotationView;
        }
        
        return annotationView;
    } else if([annotation isKindOfClass:[MAPointAnnotation class]]) {
        NSString *pointReuseIndetifier = @"pointReuseIndetifier3";
        MAAnnotationView *annotationView = (MAAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
        if (annotationView == nil) {
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndetifier];
            annotationView.canShowCallout = YES;
        }
        
        if ([annotation.title isEqualToString:@"route"]) {
            annotationView.enabled = NO;
            annotationView.image = [UIImage imageNamed:@""];
        }
        
        [self.car1View.superview bringSubviewToFront:self.car1View];
        [self.car2View.superview bringSubviewToFront:self.car2View];
        
        return annotationView;
    }
    
    return nil;
}

- (MAPolylineRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay {
    if(overlay == self.fullTraceLine) {
        MAPolylineRenderer *polylineView = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        
        polylineView.lineWidth   = 6.f;
        polylineView.strokeColor = [UIColor colorWithRed:0 green:0.47 blue:1.0 alpha:0.9];
        
        return polylineView;
    } else if(overlay == self.passedTraceLine) {
        MAPolylineRenderer *polylineView = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        
        polylineView.lineWidth   = 6.f;
        polylineView.strokeColor = [UIColor grayColor];
        
        return polylineView;
    }
    
    return nil;
}

- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view {
    NSLog(@"cooridnate :%f, %f", view.annotation.coordinate.latitude, view.annotation.coordinate.longitude);
}

#pragma mark life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _driveCount = 0;
    
    _runningTime = 0;
    
     self.mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
       self.mapView.delegate = self;
       self.mapView.showsUserLocation = true;
       self.mapView.userTrackingMode = MAUserTrackingModeFollow;
       [self.view addSubview:self.mapView];
    
    [self.view addSubview:self.mapView];
    
    [self initBtn];
    
    [self initDistanceView];
    
    int count = sizeof(s_coords) / sizeof(s_coords[0]);
    double sum = 0;
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
    for(int i = 0; i < count - 1; ++i) {
        CLLocation *begin = [[CLLocation alloc] initWithLatitude:s_coords[i].latitude longitude:s_coords[i].longitude];
        CLLocation *end = [[CLLocation alloc] initWithLatitude:s_coords[i+1].latitude longitude:s_coords[i+1].longitude];
        CLLocationDistance distance = [end distanceFromLocation:begin];
        [arr addObject:[NSNumber numberWithDouble:distance]];
        sum += distance;
    }
    
    double distance = 0;
    
    for (int i = 0; i < arr.count; i++) {
        distance = distance + [arr[i] doubleValue];
    }
    
    NSLog(@"总距离:%f",distance);
    
    self.distanceArray = arr;
    self.sumDistance = sum;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)initRoute {
    int count = sizeof(s_coords) / sizeof(s_coords[0]);
    
//    self.fullTraceLine = [MAPolyline polylineWithCoordinates:s_coords count:count];
//    [self.mapView addOverlay:self.fullTraceLine];
    
    NSMutableArray * routeAnno = [NSMutableArray array];
    for (int i = 0 ; i < count; i++) {
        MAPointAnnotation * a = [[MAPointAnnotation alloc] init];
        a.coordinate = s_coords[i];
        a.title = @"route";
        [routeAnno addObject:a];
    }
    [self.mapView addAnnotations:routeAnno];
    [self.mapView showAnnotations:routeAnno animated:NO];
    
    __weak typeof(self) weakSelf = self;
    
    self.car1 = [[MovingAnnotationView alloc] init];
    self.car1.title = @"Car1";
    self.car1.traveledRouteBlock = ^{
        [weakSelf removeCar1TraveledRoute];
    };
    [self.mapView addAnnotation:self.car1];
    
    self.car2 = [[CustomMovingAnnotation alloc] init];
    self.car2.stepCallback = ^() {
        [weakSelf updatePassedTrace];
    };
    self.car2.title = @"Car2";
    [self.mapView addAnnotation:self.car2];
    
    [self.car1 setCoordinate:s_coords[0]];
    [self.car2 setCoordinate:s_coords[0]];
    
    
#if 0
    const int carCount = 100;
    self.carsArray = [NSMutableArray arrayWithCapacity:carCount];
    for(int i = 0; i < carCount; ++i) {
        MAAnimatedAnnotation *car = [[MAAnimatedAnnotation alloc] init];
        car.title = [NSString stringWithFormat:@"car_%d", i];
        float deltaX = ((float)(rand() % 100)) / 1000.0;
        float deltaY = ((float)(rand() % 100)) / 1000.0;
        car.coordinate = CLLocationCoordinate2DMake(39.97617053371078 + deltaX, 116.3499049793749 + deltaY);
        [self.carsArray addObject:car];
    }
    [self.mapView addAnnotations:self.carsArray];
    
    [NSTimer scheduledTimerWithTimeInterval:5 repeats:YES block:^(NSTimer * _Nonnull timer) {
        int temp = rand() % 10;
        for(int i = 0; i < carCount; ++i) {
            if(i % temp == 0) {
                MAAnimatedAnnotation *car = [self.carsArray objectAtIndex:i];
                float deltaX = ((float)(rand() % 10)) / 1000.0;
                float deltaY = ((float)(rand() % 10)) / 1000.0;
                CLLocationCoordinate2D coord = car.coordinate;
                if(i % 2 == 0) {
                    coord.latitude += deltaX;
                    coord.longitude += deltaY;
                } else {
                    coord.latitude -= deltaX;
                    coord.longitude -= deltaY;
                }
                [car addMoveAnimationWithKeyCoordinates:&coord count:1 withDuration:1 withName:nil completeCallback:^(BOOL isFinished) {
                    ;
                }];
            }
        }
    }];
#endif
}

- (void)initBtn {
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame = CGRectMake(0, 100, 60, 40);
    btn.backgroundColor = [UIColor grayColor];
    [btn setTitle:@"move" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(mov) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn];
    
    UIButton * btn1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn1.frame = CGRectMake(0, 200, 60, 40);
    btn1.backgroundColor = [UIColor grayColor];
    [btn1 setTitle:@"stop" forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn1];
    
    UIButton * btn2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn2.frame = CGRectMake(0, 300, 60, 40);
    btn2.backgroundColor = [UIColor grayColor];
    [btn2 setTitle:@"pause" forState:UIControlStateNormal];
    [btn2 addTarget:self action:@selector(pause:) forControlEvents:UIControlEventTouchUpInside];
    self.pauseBtn = btn2;
    [self.view addSubview:btn2];
    
    UIButton * btn3 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn3.frame = CGRectMake(0, 400, 100, 40);
    btn3.backgroundColor = [UIColor grayColor];
    [btn3 setTitle:@"routePlan" forState:UIControlStateNormal];
    [btn3 addTarget:self action:@selector(routePlan) forControlEvents:UIControlEventTouchUpInside];
    self.pauseBtn = btn3;
    [self.view addSubview:btn3];
}

- (void)initDistanceView {
    
    [self.view addSubview:self.distanceText];
    
}
#pragma mark - Action

- (void)mov {
    
    self.distanceTimer  = [NSTimer timerWithTimeInterval:0.01
                                                  target:self
                                                selector:@selector(startCalculate:)
                                                userInfo:nil
                                                 repeats:true];
    
    [[NSRunLoop currentRunLoop]addTimer:self.distanceTimer forMode:NSRunLoopCommonModes];
    
    if(self.car1.isPaused) {
        [self pause:self.pauseBtn];
    }
    
    __weak typeof(self)weakSelf = self;
    double speed_car1 = 112 / 3.6;
    int count = sizeof(s_coords) / sizeof(s_coords[0]);

    [self.car1 setCoordinate:s_coords[0]];
    self.car1passedTraceCoordIndex = 0;

//    [self.car1 addMoveAnimationWithKeyCoordinates:s_coords count:count withDuration:self.sumDistance / speed_car1 withName:nil completeCallback:^(BOOL isFinished) {
//        weakSelf.driveCount++;
//       // [weakSelf mov];
//
//    }];

    for(int i = 1; i < count; ++i) {
        if (i == 1) {
            _distanceText.text = 0;
            _runningTime = 0;
        }
        NSNumber *num = [self.distanceArray objectAtIndex:i - 1];
        [self.car1 addMoveAnimationWithKeyCoordinates:&(s_coords[i]) count:1 withDuration:num.doubleValue / speed_car1 withName:nil completeCallback:^(BOOL isFinished) {
            weakSelf.car1passedTraceCoordIndex = i;
            if (i == count - 1) {
                [weakSelf.distanceTimer invalidate];
            }
      
        }];
    }
    
    //小车2走过的轨迹置灰色, 采用添加多个动画方法
    double speed_car2 = 100.0 / 3.6; //60 km/h
    [self.car2 setCoordinate:s_coords[0]];
    self.passedTraceCoordIndex = 0;
    for(int i = 1; i < count; ++i) {
        NSNumber *num = [self.distanceArray objectAtIndex:i - 1];
//        [self.car2 addMoveAnimationWithKeyCoordinates:&(s_coords[i]) count:1 withDuration:num.doubleValue / speed_car2 withName:nil completeCallback:^(BOOL isFinished) {
//            weakSelf.passedTraceCoordIndex = i;
//        }];
    }
}

- (void)stop {
    if(self.car1.isPaused) {
        [self pause:self.pauseBtn];
    }
    for(MAAnnotationMoveAnimation *animation in [self.car1 allMoveAnimations]) {
        [animation cancel];
    }
    self.car1.movingDirection = 0;
    [self.car1 setCoordinate:s_coords[0]];

    for(MAAnnotationMoveAnimation *animation in [self.car2 allMoveAnimations]) {
        [animation cancel];
    }
    self.car2.movingDirection = 0;
    [self.car2 setCoordinate:s_coords[0]];
    
    if(self.passedTraceLine) {
        [self.mapView removeOverlay:self.passedTraceLine];
        self.passedTraceLine = nil;
    }
    
    [_distanceTimer invalidate];
    
}

- (void)pause:(UIButton*)btn {
    self.car2.isPaused = self.car1.isPaused = !self.car1.isPaused;
    
    if(self.car1.isPaused) {
        [btn setTitle:@"resume" forState:UIControlStateNormal];
        [_distanceTimer setFireDate:[NSDate distantFuture]];
    } else {
        [btn setTitle:@"pause" forState:UIControlStateNormal];
        [_distanceTimer setFireDate:[NSDate date]];
    }
}

- (void)routePlan {
    RoutePlanViewController *vc = [[RoutePlanViewController alloc] init];
    vc.hidesBottomBarWhenPushed = true;
    [self.navigationController pushViewController:vc animated:true];
}

//小车1走过的路线清空
- (void)removeCar1TraveledRoute {
//    if(self.car1.isAnimationFinished) {
//
//        return;
//    }
//
//    if(self.fullTraceLine) {
//        [self.mapView removeOverlay:self.fullTraceLine];
//    }
//    int needCount = self.car1passedTraceCoordIndex + 2;
//    CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * needCount);
//
//    memcpy(coords, s_coords, sizeof(CLLocationCoordinate2D) * (self.car1passedTraceCoordIndex + 1));
//    coords[needCount - 1] = self.car1.coordinate;
//    self.fullTraceLine = [MAPolyline polylineWithCoordinates:coords count:needCount];
//    [self.mapView addOverlay:self.fullTraceLine];
//
//    if(coords) {
//        free(coords);
//    }
    
       if(self.car1.isAnimationFinished) {

           return;
       }

       if(self.fullTraceLine) {
           [self.mapView removeOverlay:self.fullTraceLine];
       }
       int needCount = self.car1passedTraceCoordIndex + 2;
       CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * needCount);

       memcpy(coords, s_coords, sizeof(CLLocationCoordinate2D) * (self.car1passedTraceCoordIndex + 1));
       coords[needCount - 1] = self.car1.coordinate;
       
       self.fullTraceLine = [MAPolyline polylineWithCoordinates:coords count:needCount];
       [self.mapView addOverlay:self.fullTraceLine];

       if(coords) {
           free(coords);
       }

}

//小车2走过的轨迹置灰色
- (void)updatePassedTrace {
    if(self.car2.isAnimationFinished) {
        
        return;
    }
    
    if(self.passedTraceLine) {
        [self.mapView removeOverlay:self.passedTraceLine];
    }
    
    NSLog(@"%d",self.passedTraceCoordIndex);
    
    int needCount = self.passedTraceCoordIndex + 2;
    CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * needCount);
    
    memcpy(coords, s_coords, sizeof(CLLocationCoordinate2D) * (self.passedTraceCoordIndex + 1));
    coords[needCount - 1] = self.car2.coordinate;
    self.passedTraceLine = [MAPolyline polylineWithCoordinates:coords count:needCount];
    [self.mapView addOverlay:self.passedTraceLine];
    
    if(coords) {
        free(coords);
    }
}

// 开始计算小车的运动距离
- (void)startCalculate:(NSTimer *) timer{
    
    if ([timer isValid]) {
        
        _runningTime  = _runningTime + 0.01;
        
        self.distanceText.text = [NSString stringWithFormat:@"%fkm",(112 / 3.6) * _runningTime / 1000];
        //NSLog(@"%f",(112 / 3.6) * _runningTime / 1000);
    }
    
    
}

- (UILabel *)distanceText {
    if (!_distanceText) {
        _distanceText = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 300, 40)];
        _distanceText.textColor = [UIColor blackColor];
    }
    return _distanceText;
}

@end
