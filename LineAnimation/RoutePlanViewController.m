//
//  RoutePlanViewController.m
//  LineAnimation
//
//  Created by 缪雨轩 on 2020/1/6.
//  Copyright © 2020 miaoyuxuan. All rights reserved.
//

#import "RoutePlanViewController.h"

#define car1Speed 10000 / 3.6 // 车辆1的速度
#define kSearchCity @"" // 关键字搜索的城市

static const NSInteger RoutePlanningPaddingEdge = 110;
static const NSString *RoutePlanningViewControllerStartTitle = @"起点";
static const NSString *RoutePlanningViewControllerDestinationTitle = @"终点";

@interface RoutePlanViewController ()<MAMapViewDelegate,AMapSearchDelegate,UITextFieldDelegate>

@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, strong) AMapSearchAPI *search;
@property (nonatomic, strong) MAPointAnnotation *startAnnotation;
@property (nonatomic, strong) MAPointAnnotation *destinationAnnotation;
@property (nonatomic, assign) CLLocationCoordinate2D startCoordinate;
@property (nonatomic, assign) CLLocationCoordinate2D destinationCoordinate;
@property (strong, nonatomic) AMapRoute *route;  //路径规划信息
@property (strong, nonatomic) AMapPath *path;  //路径规划信息
@property (strong, nonatomic) AMapStep *step;  //路径规划信息
@property (strong, nonatomic) MANaviRoute * naviRoute;  //用于显示当前路线方案.
@property (assign, nonatomic) NSUInteger totalRouteNums;  //总共规划的线路的条数
///车头方向跟随转动
@property (nonatomic, strong) MovingAnnotationView *car1;
///全轨迹overlay
@property (nonatomic, strong) MAPolyline *fullTraceLine;
@property (nonatomic, assign) int car1passedTraceCoordIndex;
@property (nonatomic, assign) double sumDistance;

@property (nonatomic, weak) MAAnnotationView *car1View;
@property (nonatomic, strong) NSArray *distanceArray;
@property (nonatomic, strong) NSMutableArray *stepDetailArray;
@property (nonatomic, strong) UIButton *pauseBtn;
@property (nonatomic, strong) UITextField *poiNameSearchTextField;
@property (nonatomic, strong) NSMutableArray *tips;
@property (nonatomic, strong) AMapLocationManager *locationManager;
@end

@implementation RoutePlanViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = true;
    self.tabBarController.tabBar.hidden = true;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initBtn];
    
    [self initMap];
    
    [self initTextField];
    
    [self addDefaultAnnotations];
    
}

- (void)initTextField {
    [self.view addSubview:self.poiNameSearchTextField];
    self.tips = [NSMutableArray array];
}

- (void)initBtn {
    UIButton *btn1 = [[UIButton alloc] initWithFrame:CGRectMake(UIScreen.mainScreen.bounds.size.width - 100, UIScreen.mainScreen.bounds.size.height - 100, 50, 50)];
    btn1.backgroundColor = [UIColor systemBlueColor];
    [btn1 setTitle:@"展示全局" forState:UIControlStateNormal];
    btn1.titleLabel.font = [UIFont systemFontOfSize:12];
    [btn1 addTarget:self action:@selector(btn1Click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
    
    UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(UIScreen.mainScreen.bounds.size.width - 100, UIScreen.mainScreen.bounds.size.height - 300, 50, 50)];
    btn2.backgroundColor = [UIColor systemBlueColor];
    [btn2 setTitle:@"出发" forState:UIControlStateNormal];
    btn2.titleLabel.font = [UIFont systemFontOfSize:12];
    [btn2 addTarget:self action:@selector(btn2Click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn2];
    
    UIButton *btn3 = [[UIButton alloc] initWithFrame:CGRectMake(UIScreen.mainScreen.bounds.size.width - 100, UIScreen.mainScreen.bounds.size.height - 200, 50, 50)];
    btn3.backgroundColor = [UIColor systemBlueColor];
    [btn3 setTitle:@"暂停" forState:UIControlStateNormal];
    btn3.titleLabel.font = [UIFont systemFontOfSize:12];
    [btn3 addTarget:self action:@selector(pause:) forControlEvents:UIControlEventTouchUpInside];
    self.pauseBtn = btn3;
    [self.view addSubview:btn3];
    
    UIButton *btn4 = [[UIButton alloc] initWithFrame:CGRectMake(UIScreen.mainScreen.bounds.size.width - 100, UIScreen.mainScreen.bounds.size.height - 400, 50, 50)];
    btn4.backgroundColor = [UIColor systemBlueColor];
    [btn4 setTitle:@"路径规划" forState:UIControlStateNormal];
    btn4.titleLabel.font = [UIFont systemFontOfSize:12];
    [btn4 addTarget:self action:@selector(btn4Click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn4];
        
}
   
- (void)initMap {
    
    self.mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.showsIndoorMap = YES;
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = true;
    self.mapView.userTrackingMode = MAUserTrackingModeFollow;
    self.mapView.zoomLevel = 10;
    [self.view addSubview:self.mapView];
    [self.view sendSubviewToBack:self.mapView];
    
    self.search = [[AMapSearchAPI alloc] init];
    self.search.delegate = self;

}

- (void)initRoute:(NSMutableArray *)stepArray {
    
    CLLocationCoordinate2D pathCoors[[stepArray count]];

    for (int i = 0; i < stepArray.count; i++) {
        CLLocationCoordinate2D coor;
        coor.latitude = [[stepArray[i] componentsSeparatedByString:@","][1] doubleValue];
        coor.longitude = [[stepArray[i] componentsSeparatedByString:@","][0] doubleValue];
        pathCoors[i] = coor;
    }
    
    int count = (int)sizeof(pathCoors) / sizeof(pathCoors[0]);
    double sum = 0;
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
    for(int i = 0; i < count - 1; ++i) {
        CLLocation *begin = [[CLLocation alloc] initWithLatitude:pathCoors[i].latitude longitude:pathCoors[i].longitude];
        CLLocation *end = [[CLLocation alloc] initWithLatitude:pathCoors[i+1].latitude longitude:pathCoors[i+1].longitude];
        CLLocationDistance distance = [end distanceFromLocation:begin];
        [arr addObject:[NSNumber numberWithDouble:distance]];
        sum += distance;
    }
    
//    double distance = 0;
//
//    for (int i = 0; i < arr.count; i++) {
//        distance = distance + [arr[i] doubleValue];
//    }

    self.distanceArray = arr;
    
//        int countt = (int)sizeof(pathCoors) / sizeof(pathCoors[0]);
//    
//        NSMutableArray * routeAnno = [NSMutableArray array];
//        for (int i = 0 ; i < countt; i++) {
//            MAPointAnnotation * a = [[MAPointAnnotation alloc] init];
//            a.coordinate = pathCoors[i];
//            a.title = @"route";
//            [routeAnno addObject:a];
//        }
//        [self.mapView addAnnotations:routeAnno];
//        [self.mapView showAnnotations:routeAnno animated:NO];
        
        __weak typeof(self) weakSelf = self;

        self.car1 = [[MovingAnnotationView alloc] init];
        self.car1.title = @"Car1";
        if (self.car1) {
            self.car1.traveledRouteBlock = ^{
                [weakSelf removeCar1TraveledRoute:stepArray];
            };
        }
        
        if (self.car1) {
            [self.mapView removeAnnotation:self.car1];
        }
    
        [self.mapView addAnnotation:self.car1];

        [self.car1 setCoordinate:pathCoors[0]];
        
    [self showGlobalView];
    
}

- (void)setUpPosition:(CLLocationCoordinate2D )startCoordinate  destinationCoordinate:(CLLocationCoordinate2D )destinationCoordinate {
    
    self.startAnnotation.coordinate = startCoordinate;
    self.destinationAnnotation.coordinate = destinationCoordinate;

    AMapRidingRouteSearchRequest *navi = [[AMapRidingRouteSearchRequest alloc] init];

    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:self.startCoordinate.latitude
                                           longitude:self.startCoordinate.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:self.destinationCoordinate.latitude
                                                longitude:self.destinationCoordinate.longitude];
    
    [self.search AMapRidingRouteSearch:navi];
}

//在地图上添加起始和终点的标注点
- (void)addDefaultAnnotations {

    MAPointAnnotation *startAnnotation = [[MAPointAnnotation alloc] init];
    startAnnotation.coordinate = self.startCoordinate;
    startAnnotation.title = (NSString *)RoutePlanningViewControllerStartTitle;
    startAnnotation.subtitle = [NSString stringWithFormat:@"{%f, %f}", self.startCoordinate.latitude, self.startCoordinate.longitude];
    self.startAnnotation = startAnnotation;
    
    MAPointAnnotation *destinationAnnotation = [[MAPointAnnotation alloc] init];
    destinationAnnotation.coordinate = self.destinationCoordinate;
    destinationAnnotation.title = (NSString *)RoutePlanningViewControllerDestinationTitle;
    destinationAnnotation.subtitle = [NSString stringWithFormat:@"{%f, %f}", self.destinationCoordinate.latitude, self.destinationCoordinate.longitude];
    self.destinationAnnotation = destinationAnnotation;
    
    [self.mapView addAnnotation:startAnnotation];
    [self.mapView addAnnotation:destinationAnnotation];
}

/* 路径规划搜索回调. */
- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response
{
    if (response.route == nil)
    {
        return;
    }
    
    self.route = response.route;

     self.totalRouteNums = self.route.paths.count;
    _path = (AMapPath *)self.route.paths[0];
    NSArray *stepArr = _path.steps;
   NSMutableArray  *stepArray = [NSMutableArray new];
   for (_step in stepArr) {
       NSMutableArray *partStepArray = (NSMutableArray *)[_step.polyline componentsSeparatedByString:@";"];
       [stepArray addObjectsFromArray:partStepArray];
   }
    
    NSMutableArray *finalArray = [NSMutableArray new];
    
    for (NSString *coordString in stepArray) {
        if (![finalArray containsObject:coordString]) {
            [finalArray addObject:coordString];
        }
    }
    
    [self onRouteSearchDone];
        
    [self initRoute:finalArray];
    
    self.stepDetailArray = finalArray;
}

- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error
{
    if (error) {
        [SVProgressHUD dismiss];
        [self.view makeToast:@"路径规划失败" duration:1.0 position:CSToastPositionCenter];
    }
}

//地图上覆盖物的渲染，可以设置路径线路的宽度，颜色等
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay {
    
    //虚线，如需要步行的
    if ([overlay isKindOfClass:[LineDashPolyline class]]) {
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:((LineDashPolyline *)overlay).polyline];
        polylineRenderer.lineWidth = 6;
        polylineRenderer.lineDashType = kMALineDashTypeSquare;
        polylineRenderer.strokeColor = [UIColor redColor];
        
        return polylineRenderer;
    }
    
    //showTraffic为NO时，不需要带实时路况，路径为单一颜色
    if ([overlay isKindOfClass:[MANaviPolyline class]]) {
        MANaviPolyline *naviPolyline = (MANaviPolyline *)overlay;
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:naviPolyline.polyline];
        
        polylineRenderer.lineWidth = 6;
        
        if (naviPolyline.type == MANaviAnnotationTypeWalking) {
            polylineRenderer.strokeColor = self.naviRoute.walkingColor;
        } else if (naviPolyline.type == MANaviAnnotationTypeRailway) {
            polylineRenderer.strokeColor = self.naviRoute.railwayColor;
        } else {
            polylineRenderer.strokeColor = [UIColor systemBlueColor];
        }
        
        return polylineRenderer;
    }
    
    //showTraffic为YES时，需要带实时路况，路径为多颜色渐变
    if ([overlay isKindOfClass:[MAMultiPolyline class]]) {
        MAMultiColoredPolylineRenderer * polylineRenderer = [[MAMultiColoredPolylineRenderer alloc] initWithMultiPolyline:overlay];
        
        polylineRenderer.lineWidth = 6;
        polylineRenderer.strokeColors = [self.naviRoute.multiPolylineColors copy];
        
        return polylineRenderer;
    }
    
    if(overlay == self.fullTraceLine) {
        MAPolylineRenderer *polylineView = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        
        polylineView.lineWidth   = 6.f;
        polylineView.strokeColor = [UIColor whiteColor];
        
        return polylineView;
    }
    
    
    return nil;
}

//地图上的起始点，终点，拐点的标注，可以自定义图标展示等,只要有标注点需要显示，该回调就会被调用
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation {

    if ([annotation isKindOfClass:[MAUserLocation class]]) {
       NSString *pointReuseIndetifier = @"pointReuseIndetifier1";

       MAAnnotationView *annotationView = (MAAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
       if(!annotationView) {
           annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndetifier];

           annotationView.canShowCallout = YES;

           UIImage *imge  =  [UIImage imageNamed:@"gpsStat2"];
           annotationView.image =  imge;

           if(annotation == self.car1) {
               self.car1View = annotationView;
           }
       }

       return annotationView;

    }
    
    if ([annotation isKindOfClass:[POIAnnotation class]] || [annotation isKindOfClass:[AMapTipAnnotation class]])
    {
        static NSString *tipIdentifier = @"poiIdentifier";
        
        MAPinAnnotationView *poiAnnotationView = (MAPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:tipIdentifier];
        if (poiAnnotationView == nil)
        {
            poiAnnotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:tipIdentifier];
        }
        
        poiAnnotationView.canShowCallout = YES;
        poiAnnotationView.image = [UIImage imageNamed:@"placeAnnotation"];
        
        return poiAnnotationView;
    }
    
//    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
//
//        //标注的view的初始化和复用
//        static NSString *routePlanningCellIdentifier = @"RoutePlanningCellIdentifier";
//
//        MAAnnotationView *poiAnnotationView = (MAAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:routePlanningCellIdentifier];
//
//        if (poiAnnotationView == nil) {
//            poiAnnotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:routePlanningCellIdentifier];
//        }
//
//        poiAnnotationView.canShowCallout = YES;
//        poiAnnotationView.image = nil;
//
//        //拐点的图标标注
//        if ([annotation isKindOfClass:[MANaviAnnotation class]]) {
//            switch (((MANaviAnnotation*)annotation).type) {
//                case MANaviAnnotationTypeRailway:
//                    poiAnnotationView.image = [UIImage imageNamed:@"railway_station"];
//                    break;
//
//                case MANaviAnnotationTypeBus:
//                    poiAnnotationView.image = [UIImage imageNamed:@"bus"];
//                    break;
//
//                case MANaviAnnotationTypeDrive:
//                    poiAnnotationView.image = [UIImage imageNamed:@"car"];
//                    break;
//
//                case MANaviAnnotationTypeWalking:
//                    poiAnnotationView.image = [UIImage imageNamed:@"man"];
//                    break;
//
//                case MANaviAnnotationTypeRiding:
//                    poiAnnotationView.image = [UIImage imageNamed:@"ride"];
//                    break;
//
//                default:
//                    break;
//            }
//        }else{
//            //起点，终点的图标标注
//            if ([[annotation title] isEqualToString:(NSString*)RoutePlanningViewControllerStartTitle]) {
//                poiAnnotationView.image = [UIImage imageNamed:@"startPoint"];  //起点
//            }else if([[annotation title] isEqualToString:(NSString*)RoutePlanningViewControllerDestinationTitle]){
//                poiAnnotationView.image = [UIImage imageNamed:@"endPoint"];  //终点
//            }
//
//        }
//
//        return poiAnnotationView;
//    }
    
    if ([annotation isKindOfClass:[MovingAnnotationView class]]) {
           if (annotation == self.car1) {
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
           }
       } else if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
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
           
           return annotationView;
       }
    
    return nil;
}

/* 输入提示回调. */
- (void)onInputTipsSearchDone:(AMapInputTipsSearchRequest *)request response:(AMapInputTipsSearchResponse *)response
{
    
    [self.naviRoute removeFromMapView];  //清空地图上已有的路线
    
    if (response.count == 0)
    {
        return;
    }
    
    [self.tips setArray:response.tips];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapView removeAnnotations:self.mapView.annotations];
            
                for (AMapTip *tip in self.tips) {
                    if (tip.uid != nil && tip.location != nil) /* 可以直接在地图打点  */
                    {
                        AMapTipAnnotation *annotation = [[AMapTipAnnotation alloc] initWithMapTip:tip];
                        [self.mapView addAnnotation:annotation];
                        [self.mapView selectAnnotation:annotation animated:YES];
                    }
                }
    });

    
}

/* POI 搜索回调. */
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    [self.naviRoute removeFromMapView];  //清空地图上已有的路线
    
    if (response.pois.count == 0)
    {
        return;
    }
    
    NSMutableArray *poiAnnotations = [NSMutableArray arrayWithCapacity:response.pois.count];
    
    [response.pois enumerateObjectsUsingBlock:^(AMapPOI *obj, NSUInteger idx, BOOL *stop) {
        
        [poiAnnotations addObject:[[POIAnnotation alloc] initWithPOI:obj]];
        
    }];
    
    /* 将结果以annotation的形式加载到地图上. */
    [self.mapView addAnnotations:poiAnnotations];
    
    /* 如果只有一个结果，设置其为中心点. */
    if (poiAnnotations.count == 1)
    {
        [self.mapView setCenterCoordinate:[poiAnnotations[0] coordinate]];
    }
    /* 如果有多个结果, 设置地图使所有的annotation都可见. */
    else
    {
        [self.mapView showAnnotations:poiAnnotations animated:NO];
    }
    
}

- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view {
    
        self.locationManager = [[AMapLocationManager alloc] init];
        // 带逆地理信息的一次定位（返回坐标和地址信息）
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
        //    //   定位超时时间，最低2s，此处设置为2s
        self.locationManager.locationTimeout = 10;
        //    //   逆地理请求超时时间，最低2s，此处设置为2s
        self.locationManager.reGeocodeTimeout = 10;
        [self.locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
            
            if (error)
            {
                 
            }
            
            self.startCoordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
            
            self.destinationCoordinate = CLLocationCoordinate2DMake(view.annotation.coordinate.latitude, view.annotation.coordinate.longitude);
        }];
}

//在地图上显示当前选择的路径
- (void)onRouteSearchDone {
    
    if (self.totalRouteNums <= 0) {
        return;
    }
    
    [self.naviRoute removeFromMapView];  //清空地图上已有的路线
        
    MANaviAnnotationType type = MANaviAnnotationTypeDrive; //骑行类型
    
    AMapGeoPoint *startPoint = [AMapGeoPoint locationWithLatitude:self.startAnnotation.coordinate.latitude longitude:self.startAnnotation.coordinate.longitude]; //起点
    
    AMapGeoPoint *endPoint = [AMapGeoPoint locationWithLatitude:self.destinationAnnotation.coordinate.latitude longitude:self.destinationAnnotation.coordinate.longitude];  //终点
    
    //根据已经规划的路径，起点，终点，规划类型，是否显示实时路况，生成显示方案
    self.naviRoute = [MANaviRoute naviRouteForPath:self.route.paths[0] withNaviType:type showTraffic:NO startPoint:startPoint endPoint:endPoint];
    
    [self.naviRoute addToMapView:self.mapView];  //显示到地图上
    
    [SVProgressHUD dismiss];
    
    
}

- (void)removeCar1TraveledRoute:(NSMutableArray *)stepArray {
       if(self.car1.isAnimationFinished) {

           return;
       }
    
    CLLocationCoordinate2D pathCoors[[stepArray count]];

    for (int i = 0; i < stepArray.count; i++) {
        CLLocationCoordinate2D coor;
        coor.latitude = [[stepArray[i] componentsSeparatedByString:@","][1] doubleValue];
        coor.longitude = [[stepArray[i] componentsSeparatedByString:@","][0] doubleValue];
        pathCoors[i] = coor;
    }

       if(self.fullTraceLine) {
           [self.mapView removeOverlay:self.fullTraceLine];
       }
       int needCount = self.car1passedTraceCoordIndex + 2;
       CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * needCount);

       memcpy(coords, pathCoors, sizeof(CLLocationCoordinate2D) * (self.car1passedTraceCoordIndex + 1));
       coords[needCount - 1] = self.car1.coordinate;
       
       self.fullTraceLine = [MAPolyline polylineWithCoordinates:coords count:needCount];
       [self.mapView addOverlay:self.fullTraceLine];

       if(coords) {
           free(coords);
       }

}

#pragma mark - Action
- (void)mov:(NSMutableArray *)stepArray {
    
    if(self.car1.isPaused) {
        [self pause:self.pauseBtn];
    }

    CLLocationCoordinate2D pathCoors[[stepArray count]];

    for (int i = 0; i < stepArray.count; i++) {
        CLLocationCoordinate2D coor;
        coor.latitude = [[stepArray[i] componentsSeparatedByString:@","][1] doubleValue];
        coor.longitude = [[stepArray[i] componentsSeparatedByString:@","][0] doubleValue];
        pathCoors[i] = coor;
    }
    
    __weak typeof(self)weakSelf = self;
    double speed_car1 = car1Speed;
    int count = sizeof(pathCoors) / sizeof(pathCoors[0]);

    [self.car1 setCoordinate:pathCoors[0]];
    self.car1passedTraceCoordIndex = 0;


    for(int i = 1; i < count; ++i) {
     
        NSNumber *num = [self.distanceArray objectAtIndex:i - 1];
        [self.car1 addMoveAnimationWithKeyCoordinates:&(pathCoors[i]) count:1 withDuration:num.doubleValue / speed_car1 withName:nil completeCallback:^(BOOL isFinished) {
            weakSelf.car1passedTraceCoordIndex = i;
           
      
        }];
    }

}

- (void)showGlobalView {
    UIEdgeInsets edgePaddingRect = UIEdgeInsetsMake(RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge);
    
    //缩放地图使其适应polylines的展示
    [self.mapView setVisibleMapRect:[CommonUtility mapRectForOverlays:self.naviRoute.routePolylines]
                        edgePadding:edgePaddingRect
                           animated:true];
}

- (void)btn1Click {
    //self.mapView.centerCoordinate = CLLocationCoordinate2DMake(self.car1.coordinate.latitude, self.car1.coordinate.longitude);
    [self showGlobalView];
}

- (void)btn2Click {
    
    [self mov:_stepDetailArray];
    
}

- (void)pause:(UIButton*)btn {
    
    self.car1.isPaused = !self.car1.isPaused;

    if(self.car1.isPaused) {
        [btn setTitle:@"继续" forState:UIControlStateNormal];

    } else {
        [btn setTitle:@"暂停" forState:UIControlStateNormal];
    }
}

- (void)btn4Click {
    
    if (self.car1) {
        [self.mapView removeAnnotation:self.car1];
    }
    
    if (self.fullTraceLine) {
        [self.mapView removeOverlay:self.fullTraceLine];
    }
    
    [SVProgressHUD showWithStatus:@"正在规划路径，请稍等..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    
    [self setUpPosition:self.startCoordinate destinationCoordinate:self.destinationCoordinate];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
//       AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
//       //request.location = [AMapGeoPoint locationWithLatitude:26.063184 longitude:119.298224];
//       request.keywords = textField.text;
//       // types属性表示限定搜索POI的类别，默认为：餐饮服务|商务住宅|生活服务
//       // POI的类型共分为20种大类别，分别为：
//       // 汽车服务|汽车销售|汽车维修|摩托车服务|餐饮服务|购物服务|生活服务|体育休闲服务|
//       // 医疗保健服务|住宿服务|风景名胜|商务住宅|政府机构及社会团体|科教文化服务|
//       // 交通设施服务|金融保险服务|公司企业|道路附属设施|地名地址信息|公共设施
//       request.sortrule = 0;
//       request.radius = 700;
//       request.requireExtension = YES;
//
//       //发起周边搜索
//       [_search AMapPOIAroundSearch: request];
    dispatch_async(dispatch_get_main_queue(), ^{
        AMapInputTipsSearchRequest *tips = [[AMapInputTipsSearchRequest alloc] init];
        tips.keywords = textField.text;
        tips.city     = kSearchCity;
        tips.cityLimit = YES;
        
        [self.search AMapInputTipsSearch:tips];
    });
    
    
    return [textField resignFirstResponder];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:true];
}

- (NSMutableArray *)stepDetailArray {
    if (!_stepDetailArray) {
        _stepDetailArray = [NSMutableArray new];
    }
    return _stepDetailArray;
}

- (UITextField *)poiNameSearchTextField {
    if (!_poiNameSearchTextField) {
        _poiNameSearchTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 50, UIScreen.mainScreen.bounds.size.width - 40, 30)];
        _poiNameSearchTextField.backgroundColor = [UIColor systemBlueColor];
        _poiNameSearchTextField.placeholder = @"请输入想要搜索的关键字";
        _poiNameSearchTextField.tintColor = [UIColor whiteColor];
        _poiNameSearchTextField.textColor = [UIColor whiteColor];
        _poiNameSearchTextField.delegate = self;
        _poiNameSearchTextField.returnKeyType = UIReturnKeySearch;
    }
    return _poiNameSearchTextField;
}

@end
