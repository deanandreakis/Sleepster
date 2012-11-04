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
@synthesize backgroundColor;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = backgroundColor;
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0"))
    {
        [[UIScreen mainScreen] setBrightness:1.0];
    }
}


- (IBAction)done:(id)sender {
	[self.bgDelegate backlightViewControllerDidFinish:self];	
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
