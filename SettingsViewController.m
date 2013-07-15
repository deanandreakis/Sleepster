//
//  SettingsViewController.m
//  SleepMate
//
//  Created by Dean Andreakis on 12/6/12.
//
//

#import "SettingsViewController.h"
#import "Constants.h"

@interface SettingsViewController ()

@property (strong, nonatomic) UIButton *menuBtn;

@end

@implementation SettingsViewController

@synthesize menuBtn;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark sound and background values

-(IBAction)soundMixSwitch:(id)sender
{
    //TODO: storekit logic
    UISwitch* switcher = (UISwitch *)sender;
    if([switcher isOn])
    {
        //NSLog(@"switch is ON");
    }
    else{
        //NSLog(@"switch is OFF");
    }
}

-(IBAction)backgroundMixSwitch:(id)sender
{
    //TODO: storekit logic
    UISwitch* switcher = (UISwitch *)sender;
    if([switcher isOn])
    {
        //NSLog(@"switch is ON");
    }
    else{
        //NSLog(@"switch is OFF");
    }
}

@end
