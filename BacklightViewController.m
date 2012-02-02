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


- (void)dealloc {
    [super dealloc];
}


@end
