//
//  FlipsideViewController.h
//  iSleep
//
//  Created by Dean Andreakis on 12/6/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

@protocol FlipsideViewControllerDelegate;

@interface InformationViewController : UIViewController {
	id <FlipsideViewControllerDelegate> __weak delegate;
}

@property (nonatomic, weak) id <FlipsideViewControllerDelegate> delegate;

@end


@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(InformationViewController *)controller;
@end

