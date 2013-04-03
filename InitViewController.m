//
//  InitViewController.m
//  SleepMate
//
//  Created by Dean Andreakis on 3/10/13.
//
//

#import "InitViewController.h"
#import "MainViewController.h"
#import "iSleepAppDelegate.h"

@interface InitViewController ()

@end

@implementation InitViewController

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
	// Do any additional setup after loading the view.
    self.topViewController = [iSleepAppDelegate appDelegate].mainViewController;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
