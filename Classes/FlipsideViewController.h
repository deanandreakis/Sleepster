//
//  FlipsideViewController.h
//  iSleep
//
//  Created by Dean Andreakis on 12/6/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

@protocol FlipsideViewControllerDelegate;

@interface FlipsideViewController : UIViewController {
	id <FlipsideViewControllerDelegate> delegate;
}

@property (nonatomic, assign) id <FlipsideViewControllerDelegate> delegate;
- (IBAction)done;
- (IBAction)rate;

@end


@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

