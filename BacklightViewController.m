//
//  BacklightViewController.m
//  iSleep
//
//  Created by Dean Andreakis on 6/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BacklightViewController.h"

@implementation BacklightViewController

@synthesize bgDelegate;
@synthesize backgroundColor, brightness;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = backgroundColor;
    [[UIScreen mainScreen] setBrightness:brightness];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryLevelDidChange:)
                                                 name:UIDeviceBatteryLevelDidChangeNotification
                                               object:nil];
}

- (IBAction)done:(id)sender {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.bgDelegate backlightViewControllerDidFinish:self];
}

-(void)batteryLevelDidChange
{
    float batteryLevel = [UIDevice currentDevice].batteryLevel;
    if(batteryLevel <= 0.1f && [UIDevice currentDevice].batteryState == UIDeviceBatteryStateUnplugged)
    {
        [self done:nil];
    }
    NSLog(@"BATTERY LEVEL CHANGED TO: %f", batteryLevel);
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}




@end
