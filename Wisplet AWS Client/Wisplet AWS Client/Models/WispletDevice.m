//
//  WispletDevice.m
//  WispletAWSClient
//
//  Created by Jason Musser on 4/25/16.
//  Copyright (c) 2016 Silicon Engines. All rights reserved.
//

#import "WispletDevice.h"
#import <AWSIoT/AWSIoT.h>
#import "AppDelegate.h"
#import "TemperatureSensor.h"
#import "HumiditySensor.h"
#import "IRLightLevelSensor.h"
#import "VisibleLightLevelSensor.h"
#import "PotentiometerSensor.h"
#import "StatSensor.h"

@interface WispletDevice()

@property (strong, nonatomic) id<MQTTDataDisplayDelegate> mqttDataDisplayDelegate;
@property (nonatomic,strong)NSString *deviceID;
@property (nonatomic,assign,getter = isOnline)BOOL online;
@property (nonatomic, strong)EvalKitSensorBoard *boardModel;
@property int rssi;
@property int uptime;
@property (nonatomic, strong) NSString *firmwareVersion;

@end

@implementation WispletDevice

- (instancetype)initWithDeviceID:(NSString*)deviceID isOnline:(BOOL)isOnline{
    
    if (self = [super init]) {
        self.deviceID = [deviceID lowercaseString];        self.online = isOnline;
        
        self.boardModel = [[EvalKitSensorBoard alloc] init];
        
        self.boardModel.temperatureSensor = [[TemperatureSensor alloc] init];
        self.boardModel.humiditySensor = [[HumiditySensor alloc] init];
        self.boardModel.visibleLightSensor = [[VisibleLightLevelSensor alloc] init];
        self.boardModel.irLightSensorSensor = [[IRLightLevelSensor alloc] init];
        self.boardModel.potentiometerSensor = [[PotentiometerSensor alloc] init];
        self.boardModel.statDisplaySensor = [[StatSensor alloc] init];
    }
    return self;
}

// MQTT begins
- (void)setMQTTDataDisplayDelegate:(id<MQTTDataDisplayDelegate>)delegate
{
    _mqttDataDisplayDelegate = delegate;
}

-(NSString*)getMacAddress
{
    return self.deviceID;
}

// Send integer value 0 to 999 to LED on Wisplet's Sensor Board.
// Note: sending value of 0 will cause Sensor Board's firmware version to be
// shown on LED.  Any other value from 1-999 will actually show the value.
-(void)publishStatValueToLED:(int)value
{
    AWSIoTDataManager* iotDataManager = [AWSIoTDataManager defaultIoTDataManager];
    
    NSString *appUUID = [[self appDelegate] getAppUUID];
    NSString *pubTopic = [NSString stringWithFormat:@"%@/%@/updates/pids", appUUID, [self getMacAddress]];
    NSString *payloadString = [NSString stringWithFormat:@"{\"5\": \"%d\"}", value];
    
    NSLog(@">>>>> Publishing SET PID VALUE\n>>>>> TOPIC: %@\n>>>>> PAYLOAD: %@", pubTopic, payloadString);
    [iotDataManager publishString:payloadString onTopic:pubTopic];
}

-(void)publishStatusUpdateNowRequest
{
    AWSIoTDataManager* iotDataManager = [AWSIoTDataManager defaultIoTDataManager];
    
    NSString *appUUID = [[self appDelegate] getAppUUID];
    NSString *pubTopic = [NSString stringWithFormat:@"%@/%@/updates/newstatusnow", appUUID, [self getMacAddress]];
    NSString *payloadString = @"{\"allpids\" : \"true\"}";
    
    NSLog(@">>>>> Publishing STATUS UPDATE NOW\n>>>>> TOPIC: %@\n>>>>> PAYLOAD: %@", pubTopic, payloadString);
    [iotDataManager publishString:payloadString onTopic:pubTopic];
}

-(void)publishFirmwareVersionRequest
{
    AWSIoTDataManager* iotDataManager = [AWSIoTDataManager defaultIoTDataManager];
    
    NSString *appUUID = [[self appDelegate] getAppUUID];
    NSString *pubTopic = [NSString stringWithFormat:@"%@/%@/version", appUUID, [self getMacAddress]];
    NSString *payloadString = @"";
    
    NSLog(@">>>>> Publishing REQUEST FIRMWARE VERSION\n>>>>> TOPIC: %@\n>>>>> PAYLOAD: %@", pubTopic, payloadString);
    [iotDataManager publishString:payloadString onTopic:pubTopic];
}

////////////

-(void)subscribeToMqttTopics
{
    AWSIoTDataManager* iotDataManager = [AWSIoTDataManager defaultIoTDataManager];
    
    ////// --- Sub to status updates ---
    NSString *topic = [NSString stringWithFormat:@"%@/msg/status", [self getMacAddress]];
    NSLog(@"-----Subscribing to topic: %@",topic);
    
    [iotDataManager subscribeToTopic:topic qos:0 messageCallback:^(NSData *payload) {
        NSString *stringValue = [NSString stringWithUTF8String:[payload bytes]];
        NSLog(@"<<<<< Status Update received for [%@]\n<<<<< PAYLOAD: %@", self.deviceID, stringValue);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSData *jsonData = [stringValue dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *error = nil;
            NSDictionary *myDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
            
            if(!myDictionary) {
                NSLog(@"%@",error);
                return;
            }
            
            [self setOnline:YES];
            [self populateFromDictionary:myDictionary];
            [self.mqttDataDisplayDelegate updateUIWithNewDeviceData];
            [self.mqttDataDisplayDelegate statusUpdateReceived];
        });
    }];
    
    ////// --- Sub to acks to pid set commands (turn charger off/on) ---
    NSString *topicAckChargerOffOn = [NSString stringWithFormat:@"%@/msg/updates/ackpids", [self getMacAddress]];
    // o PID# : { “success” : “true” } OR
    // o PID# : { “success” : “false”, “info” : “<string with error information>” }
    NSLog(@"-----Subscribing to topic: %@", topicAckChargerOffOn);
    [iotDataManager subscribeToTopic:topicAckChargerOffOn qos:0 messageCallback:^(NSData *payload) {
        
        NSString *stringValue = [NSString stringWithUTF8String:[payload bytes]];
        NSLog(@"<<<<< ackpids received for [%@]\n<<<<< PAYLOAD: %@", self.deviceID, stringValue);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self setOnline:YES];
            [self.mqttDataDisplayDelegate updateUIWithNewDeviceData];
            
            [self publishStatusUpdateNowRequest];
        });
    }];
    
    ////// --- Sub to acks for publishStatusUpdateNow ---
    // <from>/msg/updates/ackstatusnow
    NSString *topicAckPublishStatusUpdateNow = [NSString stringWithFormat:@"%@/msg/updates/ackstatusnow", [self getMacAddress]];
    NSLog(@"-----Subscribing to topic: %@", topicAckPublishStatusUpdateNow);
    [iotDataManager subscribeToTopic:topicAckPublishStatusUpdateNow qos:0 messageCallback:^(NSData *payload) {
        
        NSString *stringValue = [NSString stringWithUTF8String:[payload bytes]];
        NSLog(@"<<<<< ackstatusnow received for [%@]\n<<<<< TOPIC: %@", self.deviceID, stringValue);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self setOnline:YES];
            [self.mqttDataDisplayDelegate updateUIWithNewDeviceData];
        });
    }];
    
    ////// --- Sub to alert messages ---
    //_topic = @"+/msg/alert";
    NSString *topicAlertMessage = [NSString stringWithFormat:@"%@/msg/alert", [self getMacAddress]];
    NSLog(@"-----Subscribing to: %@", topicAlertMessage);
    
    [iotDataManager subscribeToTopic:topicAlertMessage qos:0 messageCallback:^(NSData *payload) {
        NSString *stringValue = [NSString stringWithUTF8String:[payload bytes]];
        NSLog(@"<<<<< MQTT ALERT message received for [%@]\n<<<<< PAYLOAD: %@", self.deviceID, stringValue);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSData *jsonData = [stringValue dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *error = nil;
            NSDictionary *myDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
            
            if(!myDictionary) {
                NSLog(@"%@",error);
                return;
            }
            
            // PAYLOAD: { "PID": 4, "PIDName": "p4", "PIDValue": "3.30", "T1": "3.00", "T2": "0.00", "Rule": "If Greater Than or Equal to T1", "RuleNumber": 7 }
            NSString *alertMessageText = @"ALERT received from Wisplet";
            if(myDictionary[@"PID"])
            {
                NSString *value = [myDictionary valueForKey:@"PID"];
                //int pidIndex = [value intValue];
                alertMessageText = [NSString stringWithFormat:@"%@\nPID: %@", alertMessageText, value];
                
            }
            if(myDictionary[@"Rule"])
            {
                NSString *value = [myDictionary valueForKey:@"Rule"];
                alertMessageText = [NSString stringWithFormat:@"%@\nRule: '%@'", alertMessageText, value];
            }
            
            [self setOnline:YES];
            [self.mqttDataDisplayDelegate updateUIWithNewDeviceData];
            [self.mqttDataDisplayDelegate alertReceived:alertMessageText];
        });
    }];
    
    ////// --- Sub to firmware version responses ---
    //_topic = @"+/msg/version";
    NSString *topicFirmwareVersion = [NSString stringWithFormat:@"%@/msg/version", [self getMacAddress]];
    NSLog(@"-----Subscribing to: %@", topicFirmwareVersion);
    
    [iotDataManager subscribeToTopic:topicFirmwareVersion qos:0 messageCallback:^(NSData *payload) {
        NSString *stringValue = [NSString stringWithUTF8String:[payload bytes]];
        NSLog(@"<<<<< MQTT FIRMWARE version message received for [%@]\n<<<<< PAYLOAD: %@", self.deviceID, stringValue);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSData *jsonData = [stringValue dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *error = nil;
            NSDictionary *myDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
            
            if(!myDictionary) {
                NSLog(@"%@",error);
                return;
            }
            
            [self setOnline:YES];
            [self populateFirmwareVersionFromDictionary:myDictionary];
            
            [self.mqttDataDisplayDelegate updateUIWithNewDeviceData];
        });
    }];
}

-(void)unsubscribeFromMqttTopics
{
    // unsubscribe from AWS IoT MQTT topics
    AWSIoTDataManager* iotDataManager = [AWSIoTDataManager defaultIoTDataManager];
    
    NSString *topic = [NSString stringWithFormat:@"%@/msg/status", [self getMacAddress]];
    [iotDataManager unsubscribeTopic:topic];
    
    NSString *topicAckChargerOffOn = [NSString stringWithFormat:@"%@/msg/updates/ackpids", [self getMacAddress]];
    [iotDataManager unsubscribeTopic:topicAckChargerOffOn];
    
    NSString *topicAckPublishStatusUpdateNow = [NSString stringWithFormat:@"%@/msg/updates/ackstatusnow", [self getMacAddress]];
    [iotDataManager unsubscribeTopic:topicAckPublishStatusUpdateNow];
    
    NSString *topicAlertMessage = [NSString stringWithFormat:@"%@/msg/alert", [self getMacAddress]];
    [iotDataManager unsubscribeTopic:topicAlertMessage];
    
    NSString *topicFirmwareVersion = [NSString stringWithFormat:@"%@/msg/version", [self getMacAddress]];
    [iotDataManager unsubscribeTopic:topicFirmwareVersion];
}
//-----

// Parse out payload of STATUS UPDATE message from Wisplet into respective sensor values
-(void)populateFromDictionary:(NSDictionary*)chargerDictionary {
    
    if(chargerDictionary[@"p0"]) // temp
    {
        NSString *value = [chargerDictionary valueForKey:@"p0"];
        [self.boardModel.temperatureSensor setCurrentValueString:value];
        float floatValue = [value floatValue];
        [self.boardModel.temperatureSensor setCurrentValue:floatValue];
    }
    
    if(chargerDictionary[@"p1"]) // humidity
    {
        NSString *value = [chargerDictionary valueForKey:@"p1"];
        [self.boardModel.humiditySensor setCurrentValueString:value];
        float floatValue = [value floatValue];
        [self.boardModel.humiditySensor setCurrentValue:floatValue];
    }
    
    if(chargerDictionary[@"p2"]) // visible light
    {
        NSString *value = [chargerDictionary valueForKey:@"p2"];
        [self.boardModel.visibleLightSensor setCurrentValueString:value];
        float floatValue = [value floatValue];
        [self.boardModel.visibleLightSensor setCurrentValue:floatValue];
    }
    
    if(chargerDictionary[@"p3"]) // ir light
    {
        NSString *value = [chargerDictionary valueForKey:@"p3"];
        [self.boardModel.irLightSensorSensor setCurrentValueString:value];
        float floatValue = [value floatValue];
        [self.boardModel.irLightSensorSensor setCurrentValue:floatValue];
    }
    
    if(chargerDictionary[@"p4"]) // potentiometer
    {
        NSString *value = [chargerDictionary valueForKey:@"p4"];
        [self.boardModel.potentiometerSensor setCurrentValueString:value];
        float floatValue = [value floatValue];
        [self.boardModel.potentiometerSensor setCurrentValue:floatValue];
    }
    
    if(chargerDictionary[@"p5"]) // stat
    {
        NSString *value = [chargerDictionary valueForKey:@"p5"];
        [self.boardModel.statDisplaySensor setCurrentValueString:value];
        int intValue = [value intValue];
        [self.boardModel.statDisplaySensor setCurrentValue:intValue];
    }
    
    if (chargerDictionary[@"rssi"]) // signal strength
    {
        NSString *value = [chargerDictionary valueForKey:@"rssi"];
        int intvalue = [value integerValue];
        self.rssi = intvalue;
    }
    
    if (chargerDictionary[@"uptime"]) // milliseconds
    {
        NSString *value = [chargerDictionary valueForKey:@"uptime"];
        int intvalue = [value integerValue];
        self.uptime = intvalue;
    }
}

// PAYLOAD: { "Wisplet": "2.144.352.21 2016 Mar 31", "CustomerApp": 19 }
-(void)populateFirmwareVersionFromDictionary:(NSDictionary*)chargerDictionary {
    
    if(chargerDictionary[@"Wisplet"])
    {
        NSString *value = [chargerDictionary valueForKey:@"Wisplet"];
        self.firmwareVersion = value;
        // TODO: If desired, can also pull out the CustomerApp field
    }
}


//----
-(int)getRssi
{
    return _rssi;
}

-(int)getUptime
{
    return _uptime;
}

-(NSString*)getFirmwareVersion
{
    return _firmwareVersion;
}

-(TemperatureSensor*)getTemperatureSensor
{
    return _boardModel.temperatureSensor;
}

-(HumiditySensor*)getHumiditySensor
{
    return _boardModel.humiditySensor;
}

-(VisibleLightLevelSensor*)getVisibleLightSensor
{
    return _boardModel.visibleLightSensor;
}

-(IRLightLevelSensor*)getIrLightSensor
{
    return _boardModel.irLightSensorSensor;
}

-(PotentiometerSensor*)getPotentiometerSensor
{
    return _boardModel.potentiometerSensor;
}

-(StatSensor*)getStatSensor
{
    return _boardModel.statDisplaySensor;
}

//----


- (AppDelegate *)appDelegate
{
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}


@end
