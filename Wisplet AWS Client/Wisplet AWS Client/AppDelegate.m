//
//  AppDelegate.m
//  Wisplet AWS Client
//
//  Created by Jason Musser on 4/20/16.
//  Copyright © 2016 Silicon Engines. All rights reserved.
//

#import "AppDelegate.h"
#import "WispletDevice.h"
#import "Constants.h"

#import "WispletAWSClient-Swift.h"

@interface AppDelegate ()
@property (strong, nonatomic) id<AppConnectionDisplayDelegate> appConnectionDisplayDelegate;

@property (strong, nonatomic) NSString *appUUID;
@property (strong, nonatomic) NSString *connectionStatus;

@property (strong, nonatomic) WispletDevice *wisplet;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    AWSConnection *c = [[AWSConnection alloc] init];
    [c setupAWSIoT];

    self.wisplet = [[WispletDevice alloc] initWithDeviceID:MAC_ADDRESS isOnline:NO];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
/*
-(UIStoryboard*) getStoryboard
{
    UIStoryboard *storyBoard = nil;
    storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    return storyBoard;
}
 */

// Unique identifier asociated with app's AWS IoT SDK certificate
-(NSString*)getAppUUID
{
    return _appUUID;
}

-(void)setAppUUID:(NSString*)uuid
{
    _appUUID = uuid;
}

- (void)setAppConnectionDisplayDelegate:(id<AppConnectionDisplayDelegate>)delegate
{
    _appConnectionDisplayDelegate = delegate;
}

// Called from Swift class, pushed to ViewController
- (void)setMqttConnectionStatus:(NSString*)statusString
{
    _connectionStatus = statusString;
    if (_appConnectionDisplayDelegate != nil)
    {
        [_appConnectionDisplayDelegate mqttStatusChanged:_connectionStatus];
    }
}

// Pulled from ViewController
- (NSString*)getMqttConnectionStatus
{
    return _connectionStatus;
}

-(void)setWispletDevice:(WispletDevice*)device
{
    self.wisplet = device;
}

-(WispletDevice*)getWispletDevice
{
    return self.wisplet;
}
// end AWS IoT SDK stuff


@end
