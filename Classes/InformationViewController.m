//
//  FlipsideViewController.m
//  iSleep
//
//  Created by Dean Andreakis on 12/6/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "InformationViewController.h"
#import "Constants.h"
#import <Social/Social.h>
//#import "Flurry.h"

#define reviewString @"itms-apps://itunes.apple.com/app/id417667154"

@interface InformationViewController ()

@end

@implementation InformationViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark rate button
//TODO: Broken in Beta 3...test again later
-(IBAction)rateButton:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewString]];
}

#pragma mark state preservation and restoration
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
}

@end
