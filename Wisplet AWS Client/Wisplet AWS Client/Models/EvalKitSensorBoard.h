//
//  EvalKitSensorBoard.h
//  SE-1796 Sensor Simulator
//
//  Created by Jason Musser on 3/27/15.
//  Copyright (c) 2015 Silicon Engines. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Sensor;

@interface EvalKitSensorBoard : NSObject

@property (strong, nonatomic) Sensor *temperatureSensor;
@property (strong, nonatomic) Sensor *humiditySensor;
@property (strong, nonatomic) Sensor *visibleLightSensor;
@property (strong, nonatomic) Sensor *irLightSensorSensor;
@property (strong, nonatomic) Sensor *potentiometerSensor;
@property (strong, nonatomic) Sensor *statDisplaySensor;
@end
