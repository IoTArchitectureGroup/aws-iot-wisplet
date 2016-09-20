//
//  Sensor.m
//  SE-1796 Sensor Simulator
//
//  Created by Jason Musser on 3/27/15.
//  Copyright (c) 2015 Silicon Engines. All rights reserved.
//

#import "Sensor.h"

@interface Sensor()
@end

@implementation Sensor
@synthesize mCurrentValue = _mCurrentValue;
@synthesize mCurrentValueString = _mCurrentValueString;
@synthesize mInitialValue = _mInitialValue;
@synthesize mParameterName = _mParameterName;
@synthesize mParameterUnits = _mParameterUnits;
@synthesize mMinPossibleValue = _mMinPossibleValue;
@synthesize mMaxPossibleValue = _mMaxPossibleValue;

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

-(NSString*)getParameterName {
    return self.mParameterName;
}
-(NSString*)getParameterUnits {
    return self.mParameterUnits;
}

-(NSString*)getValueAndUnits {
    NSString *vu = [NSString stringWithFormat:@"%@ %@", [self getCurrentValueString], [self getParameterUnits]];
    return vu;
}

-(float)getMinPossibleValue {
    NSLog(@"+getMinPossibleValue: %f", self.mMinPossibleValue);
    return self.mMinPossibleValue;
}

-(float)getMaxPossibleValue {
    NSLog(@"+getMaxPossibleValue: %f", self.mMaxPossibleValue);
    return self.mMaxPossibleValue;
}

-(float)getCurrentValue {
    NSLog(@"+getCurrentValue: %f", self.mCurrentValue);
    return self.mCurrentValue;
}


-(NSString*)getCurrentValueString {
    return self.mCurrentValueString;
}

// Setters
-(void)setCurrentValue:(float)value {
    self.mCurrentValue = value;
}

-(void)setCurrentValueString:(NSString*)value
{
    self.mCurrentValueString = value;
}
@end
