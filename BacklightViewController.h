//
//  BacklightViewController.h
//  iSleep
//
//  Created by Dean Andreakis on 6/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@protocol BacklightViewControllerDelegate;


@interface BacklightViewController : UIViewController {
	id <BacklightViewControllerDelegate> bgDelegate;
	UIColor *backgroundColor;
}

@property (nonatomic, assign) id <BacklightViewControllerDelegate> bgDelegate;
@property (nonatomic, assign) UIColor *backgroundColor;
- (IBAction)done:(id)sender;

@end


@protocol BacklightViewControllerDelegate
- (void)backlightViewControllerDidFinish:(BacklightViewController *)controller;
@end
