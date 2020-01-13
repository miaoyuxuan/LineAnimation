//
//  AppDelegate.m
//  LineAnimation
//
//  Created by 缪雨轩 on 2020/1/3.
//  Copyright © 2020 miaoyuxuan. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "RoutePlanViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    RoutePlanViewController *vc = [[RoutePlanViewController alloc] init];
    
    tabBarController.viewControllers = @[[[UINavigationController alloc] initWithRootViewController:vc]];
    
    self.window.rootViewController = tabBarController;
        
    [AMapServices sharedServices].apiKey = @"b08d73a5b0d8f7e184d7063efbffbcdd";
    
    return YES;
}

@end
