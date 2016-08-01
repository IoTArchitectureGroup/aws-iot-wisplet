//
//  TemperatureSensor.m
//  SE-1796 Sensor Simulator
//
//  Created by Jason Musser on 3/28/15.
//  Copyright (c) 2015 Silicon Engines. All rights reserved.
//

#import "TemperatureSensor.h"

#define TEMPERATURE_SENSOR_PARAM_CODE @"0"

@implementation TemperatureSensor

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mParameterName = @"Temperature";
        self.mParameterUnits = @"°F";
        self.mMinPossibleValue = 0.0;
        self.mMaxPossibleValue = 200.0;
    }
    return self;
}

-(NSString*)getParameterCode {
    return TEMPERATURE_SENSOR_PARAM_CODE;
}

-(SensorType)getSensorType {
    return TEMPERATURE_SENSOR;
}
@end