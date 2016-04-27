//
//  AboutViewController.m
//
//  Created by Jason Musser on 6/5/15.
//  Copyright (c) 2015 Silicon Engines. All rights reserved.
//

#import "AboutViewController.h"
#import "SWRevealViewController.h"
#import "AppDelegate.h"
#import "Constants.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

@synthesize nameLabel, emailLabel, cellphoneLabel, appVersionLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"Wisplet Profile";
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    // TODO: Populate app version
    NSString *appVersionString = [self appVersion];
    NSString *displayString = [NSString stringWithFormat:@"App version %@ by", appVersionString];
    [self.appVersionLabel setText:displayString];
}

-(void)viewWillAppear:(BOOL)animated
{

}

- (IBAction)sidebarButtonPressed:(id)sender {
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.revealViewController revealToggle:sender];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)iotAgIconPressed:(id)sender {
    NSURL *url = [NSURL URLWithString:IOTAG_URL];
    [[UIApplication sharedApplication] openURL:url];
}


- (IBAction)wispletIconPressed:(id)sender {
    NSURL *url = [NSURL URLWithString:IOTAG_URL];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)siliconEnginesIconPressed:(id)sender {
    NSURL *url = [NSURL URLWithString:SILICON_ENGINES_URL];
    [[UIApplication sharedApplication] openURL:url];
}

-(NSString*)appVersion
{
    // get app version
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [info objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [info objectForKey:@"CFBundleVersion"];
    NSString *buildVersionForDisplay = [NSString stringWithFormat:@"%@.%@", version, build];
    return buildVersionForDisplay;
}

- (AppDelegate *)appDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

@end
