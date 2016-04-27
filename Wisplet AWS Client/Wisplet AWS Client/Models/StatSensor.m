//
//  StatSensor.m
//  WispletAWSClient
//
//  Created by Jason Musser on 4/25/16.
//  Copyright (c) 2016 Silicon Engines. All rights reserved.
//

#import "StatSensor.h"

#define STAT_SENSOR_PARAM_CODE @"5"

@implementation StatSensor

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mParameterName = @"Stat";
        self.mParameterUnits = @"";
        self.mMinPossibleValue = 0.0;
        self.mMaxPossibleValue = 999.0;
    }
    return self;
}

-(NSString*)getParameterCode {
    return STAT_SENSOR_PARAM_CODE;
}

-(SensorType)getSensorType {
    return STAT_SENSOR;
}
@end
