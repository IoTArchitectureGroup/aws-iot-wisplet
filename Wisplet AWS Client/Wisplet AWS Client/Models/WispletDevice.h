//
//  WispletDevice.h
//  WispletAWSClient
//
//  Created by Jason Musser on 4/25/16.
//  Copyright (c) 2016 Silicon Engines. All rights reserved.
//

//TODO : Make this class abstract

#import <Foundation/Foundation.h>
#import "EvalKitSensorBoard.h"

@class TemperatureSensor;
@class HumiditySensor;
@class VisibleLightLevelSensor;
@class IRLightLevelSensor;
@class PotentiometerSensor;
@class StatSensor;

@protocol MQTTDataDisplayDelegate <NSObject>
-(void)updateUIWithNewDeviceData;
-(void)statusUpdateReceived;
-(void)alertReceived:(NSString*)text;
@end

@interface WispletDevice : NSObject

- (instancetype)initWithDeviceID:(NSString*)deviceID isOnline:(BOOL)isOnline;

// MQTT
- (void)setMQTTDataDisplayDelegate:(id<MQTTDataDisplayDelegate>)delegate;
-(NSString*)getMacAddress;
-(void)publishStatValueToLED:(int)value;
-(void)publishStatusUpdateNowRequest;
-(void)publishFirmwareVersionRequest;

-(void)subscribeToMqttTopics;
-(void)unsubscribeFromMqttTopics;

-(int)getRssi;
-(int)getUptime;
-(NSString*)getFirmwareVersion;
-(TemperatureSensor*)getTemperatureSensor;
-(HumiditySensor*)getHumiditySensor;
-(VisibleLightLevelSensor*)getVisibleLightSensor;
-(IRLightLevelSensor*)getIrLightSensor;
-(PotentiometerSensor*)getPotentiometerSensor;
-(StatSensor*)getStatSensor;


@end
