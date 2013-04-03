//
//  BackgroundsViewController.m
//  SleepMate
//
//  Created by Dean Andreakis on 12/9/12.
//
//

#import "BackgroundsViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"

@interface BackgroundsViewController ()
@property (strong, nonatomic) UIButton *menuBtn;
@end

@implementation BackgroundsViewController
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
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]])
    {
        self.slidingViewController.underLeftViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"Menu"];
    }
	
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    self.menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    menuBtn.frame = CGRectMake(8, 10, 34, 24);
    [menuBtn setBackgroundImage:[UIImage imageNamed:@"menuButton.png"] forState:UIControlStateNormal];
    [menuBtn addTarget:self action:@selector(revealMenu:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.menuBtn];//stopped at 2:11 of iOS Slide Menu Tutorial - Part 3
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
}


- (IBAction)revealMenu:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
