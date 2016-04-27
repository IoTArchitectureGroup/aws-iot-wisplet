//
//  SensorBoardViewController.m
//
//  Created by Jason Musser on 3/27/15.
//  Copyright (c) 2015 Silicon Engines. All rights reserved.
//

#import "SensorBoardViewController.h"
#import "SWRevealViewController.h"
#import "ASValueTrackingSlider.h"
#import "IOSKnobControl.h"
#import "iToast.h"
#import "TemperatureSensor.h"
#import "HumiditySensor.h"
#import "VisibleLightLevelSensor.h"
#import "IRLightLevelSensor.h"
#import "PotentiometerSensor.h"
#import "StatSensor.h"

#define KNOB_CONTROL_MIN_VALUE -2.40
#define KNOB_CONTROL_MAX_VALUE 2.40

@implementation SensorBoardViewController {
    IOSKnobControl* minControl;
    IOSKnobControl* maxControl;
    NSString* imageTitle;
}

// Called when AWS IoT MQTT broker connection status changes
-(void)mqttStatusChanged:(NSString*)status
{
    self.appConnectionStatusLabel.text = [[self appDelegate] getMqttConnectionStatus];
    self.wispletMacAddressLabel.text = [[[self appDelegate] getWispletDevice] getMacAddress];
    
    if ([status isEqualToString:@"Connected"])
    {
        self.appConnectionStatusLabel.textColor = [UIColor blackColor];
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(subscribeAfterConnect)
                                       userInfo:nil
                                        repeats:NO];
    }
    else
    {
        self.appConnectionStatusLabel.textColor = [UIColor redColor];
    }
}

// After connected to AWS IoT MQTT broker, subscribe to all messages we need from Wisplet
// (Wisplet will always be sending these--this just determines whether we receive them
// in this app for the specific Wisplet defined in Constants.h by MAC address.)
-(void)subscribeAfterConnect
{
    WispletDevice *wisplet = [[self appDelegate] getWispletDevice];
    [wisplet subscribeToMqttTopics];
    
    // Wait briefly before sending out a request for the Wisplet to send us a
    // Status Update message now.  We need to wait just a bit so the subscription
    // request for the response message has reached the AWS IoT MQTT broker.
    // We don't necessarily need to issue a 'StatusMessageNow' message--if we
    // don't, we will still receive regularly-scheduled Status Update messages,
    // but we don't want to wait when the user enters this screen in app--we want
    // the data ASAP.
    [NSTimer scheduledTimerWithTimeInterval:1.5
                                     target:self
                                   selector:@selector(requestStatusMessagesNow)
                                   userInfo:nil
                                    repeats:NO];
    
    [NSTimer scheduledTimerWithTimeInterval:2.0
                                     target:self
                                   selector:@selector(requestFirmwareVersion)
                                   userInfo:nil
                                    repeats:NO];
}

-(void)requestStatusMessagesNow
{
    WispletDevice *wisplet = [[self appDelegate] getWispletDevice];
    [wisplet publishStatusUpdateNowRequest];
}

-(void)requestFirmwareVersion
{
    WispletDevice *wisplet = [[self appDelegate] getWispletDevice];
    [wisplet publishFirmwareVersionRequest];
}

-(void)updateUIWithNewDeviceData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        WispletDevice *wisplet = [[self appDelegate] getWispletDevice];
    
        int rssiValue = [wisplet getRssi];
        int uptimeValue = [wisplet getUptime];
        NSString *firmwareVersionValue = [wisplet getFirmwareVersion];
    
        self.signalStrengthValueLabel.text = [NSString stringWithFormat:@"%d dB", rssiValue];
        self.uptimeValueLabel.text = [NSString stringWithFormat:@"%d ms", uptimeValue];
        self.firmwareVersionValueLabel.text = firmwareVersionValue;
    
        NSString* temperatureValueString = [[wisplet getTemperatureSensor] getValueAndUnits];
        NSString* humidityValueString = [[wisplet getHumiditySensor] getValueAndUnits];
        NSString* visibleLightValueString = [[wisplet getVisibleLightSensor] getValueAndUnits];
        NSString* irLightValueString = [[wisplet getIrLightSensor] getValueAndUnits];
        NSString* potValueString = [[wisplet getPotentiometerSensor] getValueAndUnits];
        NSString* statValueString = [[wisplet getStatSensor] getValueAndUnits];
    
        // Set numeric display of value
        self.temperatureValueLabel.text = temperatureValueString;
        self.humidityValueLabel.text = humidityValueString;
        self.visibleLightValueLabel.text = visibleLightValueString;
        self.irLightValueLabel.text = irLightValueString;
        self.positionLabel.text = potValueString;
        self.statValueLabel.text = statValueString;
    
        //NSLog(@"temp(%@), humidity(%@), visible light(%@), ir light(%@), pot(%@), stat(%@)", temperatureValueString, humidityValueString, visibleLightValueString, irLightValueString, potValueString, statValueString);
    
        
        float temperatureValue = [[wisplet getTemperatureSensor] getCurrentValue];
        float humidityValue = [[wisplet getHumiditySensor] getCurrentValue];
        float visibleLightValue = [[wisplet getVisibleLightSensor] getCurrentValue];
        float irLightValue = [[wisplet getIrLightSensor] getCurrentValue];
        float potValue = [[wisplet getPotentiometerSensor] getCurrentValue];
        float statValue = [[wisplet getStatSensor] getCurrentValue];
    
        //NSLog(@"temp(%f), humidity(%f), visible light(%f), ir light(%f), pot(%f), stat(%f)", temperatureValue, humidityValue, visibleLightValue, irLightValue, potValue, statValue);
    
        // Set slider handle positions
        [self.temperatureSlider setValue:temperatureValue animated:YES];
        [self.humiditySlider setValue:humidityValue animated:YES];
        [self.visibleLightLevelSlider setValue:visibleLightValue animated:YES];
        [self.irLightLevelSlider setValue:irLightValue animated:YES];
        [self.knobControl setPosition:potValue animated:YES];
        [self.statSetSlider setValue:statValue animated:YES];
        
    });
}

-(void)statusUpdateReceived
{
    // Not used in this sample app, but you could perform different behavior based on which
    // message came from the Wisplet via MQTT.
}

-(void)alertReceived:(NSString *)text
{
    NSString *toastMessageText = text;
    [[[[iToast makeText:toastMessageText]
       setGravity:iToastGravityCenter] setDuration:iToastDurationLong] show];
    
    [self requestStatusMessagesNow];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // EVERYTHING IN viewDidLoad is just UI-related, nothing AWS IoT-related.
    // See viewWillAppear for AWS-IoT stuff.
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.title = @"Wisplet + Sensor Board";
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    // For sliders to display sensor values (and slider for user to send numbers to Stat LED display)
    [self setupLabels];
    [self setupValueSliders];
    
    imageTitle = @"(none)"; // for custom IOSKnobControl(for PotentiometerSensor)
    
    // Basic continuous knob configuration (for PotentiometerSensor)
    self.knobControl = [[IOSKnobControl alloc] initWithFrame:self.knobControlView.bounds];
    self.knobControl.mode = IKCModeContinuous;
    self.knobControl.shadowOpacity = 1.0;
    self.knobControl.clipsToBounds = NO;
    // NOTE: This is an important optimization when using a custom circular knob image with a shadow.
    self.knobControl.knobRadius = 0.475 * self.knobControl.bounds.size.width;
    
    // arrange to be notified whenever the knob turns
    //[self.knobControl addTarget:self action:@selector(knobPositionChanged:) forControlEvents:UIControlEventValueChanged];
    // arrange to be notified whenver the user releases the knob
    //[self.knobControl addTarget:self action:@selector(knobReleased:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.knobControlView addSubview:self.knobControl];
    
    [self updateKnobProperties];
    [self updateKnobImage];
    //[self knobPositionChanged:self.knobControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateKnobProperties];
    //NSLog(@"Min. knob position %f, max. knob position %f", minControl.position, maxControl.position);
    
    //
    // AWS IoT/MQTT code follows:
    //
    [[self appDelegate] setAppConnectionDisplayDelegate:self]; // For getting notified of changes in APP's connectivity (not Wisplet)
    WispletDevice *wisplet = [[self appDelegate] getWispletDevice];
    [wisplet setMQTTDataDisplayDelegate:self]; // for getting notified when MQTT messages come in
    
    NSString *mqttConnectionStatus = [[self appDelegate] getMqttConnectionStatus];
    self.appConnectionStatusLabel.text = mqttConnectionStatus;
    self.wispletMacAddressLabel.text = [[[self appDelegate] getWispletDevice] getMacAddress];
    
    if ([mqttConnectionStatus isEqualToString:@"Connected"])
    {
        [self requestStatusMessagesNow];
    }
}

-(void)setupLabels {
    WispletDevice *wisplet = [[self appDelegate] getWispletDevice];
    
    self.temperatureLabel.text = [[wisplet getTemperatureSensor] getParameterName];
    self.humidityLabel.text = [[wisplet getHumiditySensor] getParameterName];
    self.visibleLightLabel.text = [[wisplet getVisibleLightSensor] getParameterName];
    self.irLightLabel.text = [[wisplet getIrLightSensor] getParameterName];
    self.potentiometerLabel.text = [[wisplet getPotentiometerSensor] getParameterName];
    self.statLabel.text = [[wisplet getStatSensor] getParameterName];
}

-(void) setupValueSliders {
    // Elaborate code just for setting up the look and feel of the pretty sliders
    
    WispletDevice *wisplet = [[self appDelegate] getWispletDevice];
    // ---- customize TEMPERATURE slider ----
    TemperatureSensor *tempSensor = [wisplet getTemperatureSensor];
    NSNumberFormatter *tempFormatter = [[NSNumberFormatter alloc] init];
    //[tempFormatter setPositiveSuffix:@"°C"];
    [tempFormatter setPositiveSuffix:[tempSensor getParameterUnits]];
    [tempFormatter setNegativeSuffix:[tempSensor getParameterUnits]];
    
    self.temperatureSlider.dataSource = self;
    [self.temperatureSlider setNumberFormatter:tempFormatter];
    self.temperatureSlider.minimumValue = [tempSensor getMinPossibleValue];
    self.temperatureSlider.maximumValue = [tempSensor getMaxPossibleValue];
    self.temperatureSlider.value = [tempSensor getCurrentValue];
    //self.temperatureSlider.popUpViewCornerRadius = 16.0;
    
    self.temperatureSlider.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:26];
    self.temperatureSlider.textColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    
    UIColor *coldBlue = [UIColor colorWithHue:0.6 saturation:0.7 brightness:1.0 alpha:1.0];
    UIColor *blue = [UIColor colorWithHue:0.55 saturation:0.75 brightness:1.0 alpha:1.0];
    UIColor *green = [UIColor colorWithHue:0.3 saturation:0.65 brightness:0.8 alpha:1.0];
    UIColor *yellow = [UIColor colorWithHue:0.15 saturation:0.9 brightness:0.9 alpha:1.0];
    UIColor *red = [UIColor colorWithHue:0.0 saturation:0.8 brightness:1.0 alpha:1.0];
    
    [self.temperatureSlider setPopUpViewAnimatedColors:@[coldBlue, blue, green, yellow, red]
                                         withPositions:@[@-20, @0, @5, @25, @60]];
    
    // Commenting next two lines out because UserInteractionEnabled is set to FALSE in storyboard for this read-only pid
    //[self.temperatureSlider addTarget:self action:@selector(tempSliderReleased:) forControlEvents:UIControlEventTouchUpInside];
    //[self.temperatureSlider addTarget:self action:@selector(tempSliderReleased:) forControlEvents:UIControlEventTouchUpOutside];
    
    
    // ---- customize HUMIDITY slider ----
    HumiditySensor *humiditySensor = [wisplet getHumiditySensor];
    self.humiditySlider.dataSource = self;
    NSNumberFormatter *humidityFormatter = [[NSNumberFormatter alloc] init];
    [humidityFormatter setNumberStyle:NSNumberFormatterPercentStyle];
    [self.humiditySlider setNumberFormatter:humidityFormatter];
    
    self.humiditySlider.minimumValue = [humiditySensor getMinPossibleValue];
    self.humiditySlider.maximumValue = [humiditySensor getMaxPossibleValue];
    self.humiditySlider.value = [humiditySensor getCurrentValue];
    
    self.humiditySlider.popUpViewCornerRadius = 16.0;
    self.humiditySlider.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:26];
    self.humiditySlider.popUpViewAnimatedColors = @[[UIColor purpleColor], [UIColor redColor], [UIColor orangeColor]];

    
    // ---- customize VISIBLE LIGHT LEVEL slider ----
    VisibleLightLevelSensor *visibleLightSensor = [wisplet getVisibleLightSensor];
    self.visibleLightLevelSlider.dataSource = self;
    
    NSNumberFormatter *visibleLightFormatter = [[NSNumberFormatter alloc] init];
    [visibleLightFormatter setNumberStyle:NSNumberFormatterPercentStyle];
    [self.visibleLightLevelSlider setNumberFormatter:visibleLightFormatter];
    
    self.visibleLightLevelSlider.minimumValue = [visibleLightSensor getMinPossibleValue];
    self.visibleLightLevelSlider.maximumValue = [visibleLightSensor getMaxPossibleValue];
    self.visibleLightLevelSlider.value = [visibleLightSensor getCurrentValue];
    
    [self.visibleLightLevelSlider setMaxFractionDigitsDisplayed:0];
    self.visibleLightLevelSlider.popUpViewColor = [UIColor colorWithHue:0.55 saturation:0.8 brightness:0.9 alpha:1.0];
    self.visibleLightLevelSlider.font = [UIFont fontWithName:@"GillSans-Bold" size:22];
    self.visibleLightLevelSlider.textColor = [UIColor colorWithHue:0.55 saturation:1.0 brightness:0.5 alpha:1];
    
    
    // ---- customize IR LIGHT LEVEL slider ----
    IRLightLevelSensor *irLightSensor = [wisplet getIrLightSensor];
    self.irLightLevelSlider.dataSource = self;

    NSNumberFormatter *irLightFormatter = [[NSNumberFormatter alloc] init];
    [irLightFormatter setNumberStyle:NSNumberFormatterPercentStyle];
    [self.irLightLevelSlider setNumberFormatter:irLightFormatter];
    
    self.irLightLevelSlider.minimumValue = [irLightSensor getMinPossibleValue];
    self.irLightLevelSlider.maximumValue = [irLightSensor getMaxPossibleValue];
    self.irLightLevelSlider.value = [irLightSensor getCurrentValue];
    
    [self.irLightLevelSlider setMaxFractionDigitsDisplayed:0];
    self.irLightLevelSlider.popUpViewColor = [UIColor colorWithHue:0.55 saturation:0.8 brightness:0.9 alpha:1.0];
    self.irLightLevelSlider.font = [UIFont fontWithName:@"GillSans-Bold" size:22];
    self.irLightLevelSlider.textColor = [UIColor colorWithHue:0.55 saturation:1.0 brightness:0.5 alpha:1];
    
    
    // ---- customize STAT slider ----
    StatSensor *statSensor = [wisplet getStatSensor];
    self.statSetSlider.dataSource = self;
    
    self.statSetSlider.minimumValue = [statSensor getMinPossibleValue];
    self.statSetSlider.maximumValue = [statSensor getMaxPossibleValue];
    self.statSetSlider.value = [statSensor getCurrentValue];
    
    [self.statSetSlider setMaxFractionDigitsDisplayed:0];
    self.statSetSlider.popUpViewColor = [UIColor colorWithHue:0.55 saturation:0.8 brightness:0.9 alpha:1.0];
    self.statSetSlider.font = [UIFont fontWithName:@"GillSans-Bold" size:22];
    self.statSetSlider.textColor = [UIColor colorWithHue:0.55 saturation:1.0 brightness:0.5 alpha:1];
    
    [self.statSetSlider addTarget:self action:@selector(statSliderReleased:) forControlEvents:UIControlEventTouchUpInside];
    [self.statSetSlider addTarget:self action:@selector(statSliderReleased:) forControlEvents:UIControlEventTouchUpOutside];
}

#pragma mark - ASValueTrackingSliderDataSource
- (NSString *)slider:(ASValueTrackingSlider *)slider stringForValue:(float)value;
{
    // The only one that really matters is statSetSlider, since all the others
    // are view-only (i.e. user interaction is disabled).
    // So the user can't move the slider control knob left or right for the
    // temperature, humidity, visible light, or ir light pids.
    // User can only move the stat slider, to send an integer down to the sensor
    // board LED.
    float sliderValue;
    if (slider == self.humiditySlider ||
        slider == self.visibleLightLevelSlider ||
        slider == self.irLightLevelSlider) {
        sliderValue = value * 100;
    } else if (slider == self.temperatureSlider ||
               slider == self.statSetSlider) {
        sliderValue = value;
    }
    
    Sensor *sensorModel;
    WispletDevice *wisplet = [[self appDelegate] getWispletDevice];
    
    if (slider == self.temperatureSlider) {
        sensorModel = [wisplet getTemperatureSensor];
    } else if (slider == self.humiditySlider) {
        sensorModel = [wisplet getHumiditySensor];
    } else if (slider == self.visibleLightLevelSlider) {
        sensorModel = [wisplet getVisibleLightSensor];
    } else if (slider == self.irLightLevelSlider) {
        sensorModel = [wisplet getIrLightSensor];
    } else if (slider == self.statSetSlider) {
        sensorModel = [wisplet getStatSensor];
    }
    
    sliderValue = roundf(sliderValue);
    NSString *s = [slider.numberFormatter stringFromNumber:@(value)];
    return s;
}

#pragma mark - Stat slider callback

// Send a pid update to Wisplet pid 5, which displays its value on the LED on the
// Wisplet eval kit's sensor board.
-(void)statSliderReleased:(ASValueTrackingSlider*)sender {
    
    int value = sender.value;
    [[[self appDelegate] getWispletDevice] publishStatValueToLED:value];
    
    NSString *toastMessageText = [NSString stringWithFormat:@"Sending stat value %d to LED...", value];
    [[[[iToast makeText:toastMessageText]
            setGravity:iToastGravityCenter] setDuration:iToastDurationNormal] show];
}

#pragma mark - Knob control callback
/* Not used in this sample app, since UserInteractionEnabled is set to FALSE for this read-only pid
- (void)knobPositionChanged:(IOSKnobControl*)sender
{
    if (sender == self.knobControl) {
        
        float knobPosition = self.knobControl.position;
        // min position is -2.40 (KNOB_CONTROL_MIN_VALUE), max is 2.40
        // Map pot sensor min value to -2.40 and max value to 2.40, and convert
        // current position into voltage value
        float minVoltage = [[self appDelegate].potentiometerSensorModel getMinPossibleValue];
        float maxVoltage = [[self appDelegate].potentiometerSensorModel getMaxPossibleValue];
        float potRange = maxVoltage - minVoltage; // assumes min is not negative
        
        float knobRange = KNOB_CONTROL_MAX_VALUE - KNOB_CONTROL_MIN_VALUE; // - because MIN will be < 0. Result = 4.8
        float knobPercent = (knobPosition - KNOB_CONTROL_MIN_VALUE) / knobRange; // - because MIN will be < 0.
        
        float potVoltage = (knobPercent * potRange) + minVoltage;
        NSString *voltageString = [NSString stringWithFormat:@"%.2fV", potVoltage];
        if ([voltageString characterAtIndex:0] == '-') {
            voltageString = [voltageString substringFromIndex:1];
        }
        
        // Store the voltage value in the pot model object
        [[self appDelegate].potentiometerSensorModel setMCurrentValue:potVoltage];
        
        self.positionLabel.text = voltageString;
    }
}

- (void)knobReleased:(IOSKnobControl*)sender
{
    if (sender == self.knobControl) {
        NSLog(@"knob released!");
    }
}
*/
-(void)setKnobTintToAlertColor {
    
    if ([self.knobControl respondsToSelector:@selector(setTintColor:)]) {
        // configure the tint color (iOS 7+ only)
        
        // minControl.tintColor = maxControl.tintColor = self.knobControl.tintColor = [UIColor greenColor];
        // minControl.tintColor = maxControl.tintColor = self.knobControl.tintColor = [UIColor blackColor];
        // minControl.tintColor = maxControl.tintColor = self.knobControl.tintColor = [UIColor whiteColor];
        
        // minControl.tintColor = maxControl.tintColor = self.knobControl.tintColor = [UIColor colorWithRed:0.627 green:0.125 blue:0.941 alpha:1.0];
        self.knobControl.tintColor = [UIColor redColor];
    }
    else {
        // can still customize piecemeal below iOS 7
        UIColor* titleColor = [UIColor whiteColor];
        [minControl setTitleColor:titleColor forState:UIControlStateNormal];
        [maxControl setTitleColor:titleColor forState:UIControlStateNormal];
        [self.knobControl setTitleColor:titleColor forState:UIControlStateNormal];
    }
 }

-(void)setKnobTintToNonAlertColor {
    
    if ([self.knobControl respondsToSelector:@selector(setTintColor:)]) {
        // configure the tint color (iOS 7+ only)
        
        // minControl.tintColor = maxControl.tintColor = self.knobControl.tintColor = [UIColor greenColor];
        // minControl.tintColor = maxControl.tintColor = self.knobControl.tintColor = [UIColor blackColor];
        // minControl.tintColor = maxControl.tintColor = self.knobControl.tintColor = [UIColor whiteColor];
        
        // minControl.tintColor = maxControl.tintColor = self.knobControl.tintColor = [UIColor colorWithRed:0.627 green:0.125 blue:0.941 alpha:1.0];
        self.knobControl.tintColor = [UIColor colorWithHue:0.5 saturation:1.0 brightness:1.0 alpha:1.0];
    }
    else {
        // can still customize piecemeal below iOS 7
        UIColor* titleColor = [UIColor whiteColor];
        [minControl setTitleColor:titleColor forState:UIControlStateNormal];
        [maxControl setTitleColor:titleColor forState:UIControlStateNormal];
        [self.knobControl setTitleColor:titleColor forState:UIControlStateNormal];
    }
}

/*
#pragma mark - Image chooser delegate
- (void)imageChosen:(NSString *)anImageTitle
{
    imageTitle = anImageTitle;
    [self updateKnobImages];
}
*/

#pragma mark - Handler for configuration controls for the custom knob control used to display potentiometer

- (void)somethingChanged:(id)sender
{
    [self updateKnobProperties];
}

#pragma mark - Internal methods for the custom knob control used to display potentiometer

- (void)updateKnobImage
{
    NSString *image = @"knob";
    if (image) {
        /*
         * If an imageTitle is specified, take that image set from the asset catalog and use it for
         * the UIControlState.Normal state. If images are not specified (or are set to nil) for other
         * states, the image for the .Normal state will be used for the knob.
         * If image sets exist beginning with the specified imageTitle and ending with -highlighted or
         * -disabled, those images will be used for the relevant states. If there is no such image set
         * in the asset catalog, the image for that state will be set to nil here.
         * If image sets exist beginning with the specified imageTitle and ending with -foreground or
         * -background, they will be used for the foregroundImage or backgroundImage properties,
         * respectively, of the control. These are mainly used for rotary dial mode and are mostly
         * absent here (nil).
         */
        [self.knobControl setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
        [self.knobControl setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@-highlighted", image]] forState:UIControlStateHighlighted];
        [self.knobControl setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@-disabled", image]] forState:UIControlStateDisabled];
        self.knobControl.backgroundImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@-background", image]];
        self.knobControl.foregroundImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@-foreground", image]];
        
        if ([image isEqualToString:@"teardrop"]) {
            self.knobControl.knobRadius = 0.0;
        }
    }
    else {
        /*
         * If no imageTitle is specified, set all these things to nil to use the default images
         * generated by the control.
         */
        [self.knobControl setImage:nil forState:UIControlStateNormal];
        [self.knobControl setImage:nil forState:UIControlStateHighlighted];
        [self.knobControl setImage:nil forState:UIControlStateDisabled];
        self.knobControl.backgroundImage = nil;
        self.knobControl.foregroundImage = nil;
        
        self.knobControl.knobRadius = 0.475 * self.knobControl.bounds.size.width;
    }
}

- (void)updateKnobProperties
{
    self.knobControl.circular = NO;
    self.knobControl.min = KNOB_CONTROL_MIN_VALUE;
    self.knobControl.max = KNOB_CONTROL_MAX_VALUE;
    self.knobControl.clockwise = YES;
    /*
    self.knobControl.circular = self.circularSwitch.on;
    self.knobControl.min = minControl.position;
    self.knobControl.max = maxControl.position;
    self.knobControl.clockwise = self.clockwiseSwitch.on;
    */
    if ([self.knobControl respondsToSelector:@selector(setTintColor:)]) {
        // configure the tint color (iOS 7+ only)
        
        // minControl.tintColor = maxControl.tintColor = self.knobControl.tintColor = [UIColor greenColor];
        // minControl.tintColor = maxControl.tintColor = self.knobControl.tintColor = [UIColor blackColor];
        // minControl.tintColor = maxControl.tintColor = self.knobControl.tintColor = [UIColor whiteColor];
        
        // minControl.tintColor = maxControl.tintColor = self.knobControl.tintColor = [UIColor colorWithRed:0.627 green:0.125 blue:0.941 alpha:1.0];
        //minControl.tintColor = maxControl.tintColor =
        self.knobControl.tintColor = [UIColor colorWithHue:0.5 saturation:1.0 brightness:1.0 alpha:1.0];
    }
    else {
        // can still customize piecemeal below iOS 7
        UIColor* titleColor = [UIColor whiteColor];
        [minControl setTitleColor:titleColor forState:UIControlStateNormal];
        [maxControl setTitleColor:titleColor forState:UIControlStateNormal];
        [self.knobControl setTitleColor:titleColor forState:UIControlStateNormal];
    }
    
    minControl.gesture = maxControl.gesture = self.knobControl.gesture = IKCGestureOneFingerRotation;
    /*
     minControl.gesture = maxControl.gesture = self.knobControl.gesture = IKCGestureOneFingerRotation + self.gestureControl.selectedSegmentIndex;
    
    minControl.clockwise = maxControl.clockwise = self.knobControl.clockwise;
    
    minControl.position = minControl.position;
    maxControl.position = maxControl.position;
    */
    // Good idea to do this to make the knob reset itself after changing certain params.
    self.knobControl.position = self.knobControl.position;
    /*
    minControl.enabled = maxControl.enabled = self.circularSwitch.on == NO;
     */
}
/*
- (void)setupMinAndMaxControls
{
    // Both controls use the same image in continuous mode with circular set to NO. The clockwise
    // property is set to the same value as the main knob (the value of self.clockwiseSwitch.on).
    // That happens in updateKnobProperties.
    minControl = [[IOSKnobControl alloc] initWithFrame:self.minControlView.bounds];
    maxControl = [[IOSKnobControl alloc] initWithFrame:self.maxControlView.bounds];
    
    minControl.mode = maxControl.mode = IKCModeContinuous;
    minControl.circular = maxControl.circular = NO;
    
    // reuse the same knobPositionChanged: method
    [minControl addTarget:self action:@selector(knobPositionChanged:) forControlEvents:UIControlEventValueChanged];
    [maxControl addTarget:self action:@selector(knobPositionChanged:) forControlEvents:UIControlEventValueChanged];
    
    // the min. control ranges from -M_PI to 0 and starts at -0.5*M_PI
    minControl.min = -M_PI + 1e-7;
    minControl.max = 0.0;
    minControl.position = -M_PI_2;
    
    // the max. control ranges from 0 to M_PI and starts at 0.5*M_PI
    maxControl.min = 0.0;
    maxControl.max = M_PI - 1e-7;
    maxControl.position = M_PI_2;
    
    // add each to its placeholder
    [self.minControlView addSubview:minControl];
    [self.maxControlView addSubview:maxControl];
}
*/

// For reveal controller (hidden side-bar menu)
- (IBAction)sidebarButtonPressed:(id)sender {
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.revealViewController revealToggle:sender];
    }
}

- (AppDelegate *)appDelegate
{
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}
@end
