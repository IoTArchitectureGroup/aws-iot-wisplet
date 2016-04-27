//
//  Sensor.h
//  SE-1796 Sensor Simulator
//
//  Created by Jason Musser on 3/27/15.
//  Copyright (c) 2015 Silicon Engines. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AlertForServer;

@interface Sensor : NSObject

typedef enum {
    TEMPERATURE_SENSOR, // 0
    HUMIDITY_SENSOR,
    VISIBLE_LIGHT_SENSOR,
    IR_LIGHT_SENSOR,
    POTENTIOMETER_SENSOR, // 4
    STAT_SENSOR, // 5
    NO_SENSOR
} SensorType;

@property (strong, nonatomic) NSString *mParameterName;
@property (strong, nonatomic) NSString *mParameterUnits;
@property (nonatomic) float mMinPossibleValue; // e.g. if temp sensor is capable of reading between 0 and 200 °C
@property (nonatomic) float mMaxPossibleValue; // e.g. if temp sensor is capable of reading between 0 and 200 °C

@property (nonatomic) float mCurrentValue;
@property (nonatomic, strong) NSString *mCurrentValueString;
@property (nonatomic) float mInitialValue; // default value to show when launched. only needs to be read via current value


-(instancetype)init;

-(SensorType)getSensorType;
-(NSString*)getParameterCode;
-(NSString*)getParameterName;
-(NSString*)getParameterUnits;
-(NSString*)getValueAndUnits;

-(float)getMinPossibleValue;
-(float)getMaxPossibleValue;

-(float)getCurrentValue;
-(NSString*)getCurrentValueString;

// Setters
-(void)setCurrentValue:(float)value;
-(void)setCurrentValueString:(NSString*)value;

@end
