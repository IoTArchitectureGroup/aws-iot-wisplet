//
//  IRLightLevelSensor.m
//  SE-1796 Sensor Simulator
//
//  Created by Jason Musser on 3/28/15.
//  Copyright (c) 2015 Silicon Engines. All rights reserved.
//

#import "IRLightLevelSensor.h"

#define IR_LIGHT_SENSOR_PARAM_CODE @"4"

@implementation IRLightLevelSensor

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mParameterName = @"IR light";
        self.mParameterUnits = @"lx";
        self.mMinPossibleValue = 0.0;
        self.mMaxPossibleValue = 999.0;
    }
    return self;
}

-(NSString*)getParameterCode {
    return IR_LIGHT_SENSOR_PARAM_CODE;
}

-(SensorType)getSensorType {
    return IR_LIGHT_SENSOR;
}
@end
