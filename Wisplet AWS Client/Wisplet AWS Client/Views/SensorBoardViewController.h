//
//  SensorBoardViewController.h
//
//  Created by Jason Musser on 3/27/15.
//  Copyright (c) 2015 Silicon Engines. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "ASValueTrackingSlider.h"
#import "WispletDevice.h"

@class IOSKnobControl;

@interface SensorBoardViewController : UIViewController <AppConnectionDisplayDelegate,
                                                            MQTTDataDisplayDelegate,
                                                            ASValueTrackingSliderDelegate,
                                                            ASValueTrackingSliderDataSource>

//- (void)adjustLayout;

// Labels to hold MQTT connection status and Wisplet information
@property (weak, nonatomic) IBOutlet UILabel *appConnectionStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *wispletMacAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *signalStrengthValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *uptimeValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *firmwareVersionValueLabel;

// Labels to hold NAMES of sensors
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *humidityLabel;
@property (weak, nonatomic) IBOutlet UILabel *visibleLightLabel;
@property (weak, nonatomic) IBOutlet UILabel *irLightLabel;
@property (weak, nonatomic) IBOutlet UILabel *potentiometerLabel;
@property (weak, nonatomic) IBOutlet UILabel *statLabel;

// Labels to hold VALUES of sensors
@property (weak, nonatomic) IBOutlet UILabel *temperatureValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *humidityValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *visibleLightValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *irLightValueLabel;
@property (nonatomic) IBOutlet UILabel* positionLabel;
@property (weak, nonatomic) IBOutlet UILabel *statValueLabel;

// Sliders and Knob to display values of sensors graphically
// (and in the case of the Stat pid, to allow the user to grab that slider which
// upon release will then cause an integer to be sent to the LED on the Wisplet
// eval kit sensor board)
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *temperatureSlider;
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *humiditySlider;
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *visibleLightLevelSlider;
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *irLightLevelSlider;
@property (nonatomic) IBOutlet UIView* knobControlView;
@property (nonatomic) IOSKnobControl* knobControl;
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *statSetSlider;

// For reveal view
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;
@property (weak, nonatomic) IBOutlet UIButton *sidebarButton2;

// Called from AWSConnection.swift via AppDelegate
-(void)mqttStatusChanged:(NSString*)status;
@end

