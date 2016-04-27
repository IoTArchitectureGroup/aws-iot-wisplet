//
//  AboutViewController.h
//
//  Created by Jason Musser on 6/5/15.
//  Copyright (c) 2015 Silicon Engines. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AboutViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;
@property (weak, nonatomic) IBOutlet UIButton *sidebarButton2;


@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellphoneLabel;

@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;

@end

