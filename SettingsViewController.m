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

@property (strong, nonatomic) IBOutlet UISwitch *bgSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *soundSwitch;

@end

@implementation SettingsViewController

@synthesize bgSwitch, soundSwitch;

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
        NSLog(@"switch is ON");
    }
    else{
        NSLog(@"switch is OFF");
    }
}

-(IBAction)backgroundMixSwitch:(id)sender
{
    //TODO: storekit logic
    UISwitch* switcher = (UISwitch *)sender;
    if([switcher isOn])//switch changed to on
    {
        NSLog(@"switch is ON");
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];//check if its ok to be on
        if(![store boolForKey:BG_STOREKIT_STATUS]) { //feature has not been purchased
            
            //put code here to put up alert/ui to ask if they want to purchase this feature
            //if they dont want to purchase then bgSwitch.on = @NO;
            
        }
        
    }
    else{
        NSLog(@"switch is OFF");
    }
}

#pragma mark switch states

-(BOOL)bgSwitchState
{
    return [bgSwitch isOn];
}

-(BOOL)soundSwitchState
{
    return [soundSwitch isOn];
}

#pragma mark state preservation and restoration
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeBool:[self.bgSwitch isOn] forKey:@"bgSwitch"];
    [coder encodeBool:[self.soundSwitch isOn]forKey:@"soundSwitch"];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    [self.bgSwitch setOn:[coder decodeBoolForKey:@"bgSwitch"]];
    [self.soundSwitch setOn:[coder decodeBoolForKey:@"soundSwitch"]];
}

@end
