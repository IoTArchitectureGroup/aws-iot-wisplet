//
//  VisibleLightLevelSensor.m
//  SE-1796 Sensor Simulator
//
//  Created by Jason Musser on 3/28/15.
//  Copyright (c) 2015 Silicon Engines. All rights reserved.
//

#import "VisibleLightLevelSensor.h"

#define VISIBLE_LIGHT_SENSOR_PARAM_CODE @"3"

@implementation VisibleLightLevelSensor

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mParameterName = @"Visible light";
        self.mParameterUnits = @"lx";
        self.mMinPossibleValue = 0.0;
        self.mMaxPossibleValue = 999.0;
    }
    return self;
}

-(NSString*)getParameterCode {
    return VISIBLE_LIGHT_SENSOR_PARAM_CODE;
}

-(SensorType)getSensorType {
    return VISIBLE_LIGHT_SENSOR;
}
@end
