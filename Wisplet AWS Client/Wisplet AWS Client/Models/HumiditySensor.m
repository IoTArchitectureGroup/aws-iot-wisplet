//
//  HumiditySensor.m
//  SE-1796 Sensor Simulator
//
//  Created by Jason Musser on 3/28/15.
//  Copyright (c) 2015 Silicon Engines. All rights reserved.
//

#import "HumiditySensor.h"

#define HUMIDITY_SENSOR_PARAM_CODE @"2"

@implementation HumiditySensor

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mParameterName = @"Humidity";
        self.mParameterUnits = @"%";
        self.mMinPossibleValue = 0.0;
        self.mMaxPossibleValue = 100.0;
    }
    return self;
}

-(NSString*)getParameterCode {
    return HUMIDITY_SENSOR_PARAM_CODE;
}

-(SensorType)getSensorType {
    return HUMIDITY_SENSOR;
}
@end
