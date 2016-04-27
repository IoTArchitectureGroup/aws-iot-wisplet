//
//  AppDelegate.h
//  Wisplet AWS Client
//
//  Created by Jason Musser on 4/20/16.
//  Copyright © 2016 Silicon Engines. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WispletDevice;

@protocol AppConnectionDisplayDelegate <NSObject>
-(void)mqttStatusChanged:(NSString*)status;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)setAppConnectionDisplayDelegate:(id<AppConnectionDisplayDelegate>)delegate;

- (void)setMqttConnectionStatus:(NSString*)statusString;
- (NSString*)getMqttConnectionStatus;

- (void)setAppUUID:(NSString*)uuid;
- (NSString*)getAppUUID;

-(void)setWispletDevice:(WispletDevice*)device;
-(WispletDevice*)getWispletDevice;

@end

