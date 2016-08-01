//
//  PotentiometerSensor.m
//  SE-1796 Sensor Simulator
//
//  Created by Jason Musser on 3/28/15.
//  Copyright (c) 2015 Silicon Engines. All rights reserved.
//

#import "PotentiometerSensor.h"

#define POTENTIOMETER_SENSOR_PARAM_CODE @"4"

@implementation PotentiometerSensor

- (instancetype)init
{
    self = [super init];
    if (self) {
        // The pot’s a-to-d value will be converted to its actual wiper voltage (rounded to the hundredths place)
        // from 0.00 V to 3.30 V using all of the 10 bit a-to-d (0 to 1023 counts) range.
        self.mParameterName = @"Potentiometer";
        self.mParameterUnits = @"V";
        self.mMinPossibleValue = 0.0;
        self.mMaxPossibleValue = 3.3;
    }
    return self;
}

-(NSString*)getParameterCode {
    return POTENTIOMETER_SENSOR_PARAM_CODE;
}

-(SensorType)getSensorType {
    return POTENTIOMETER_SENSOR;
}
@end
