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
	id <BacklightViewControllerDelegate> __weak bgDelegate;
	UIColor *__weak backgroundColor;
}

@property (nonatomic, weak) id <BacklightViewControllerDelegate> bgDelegate;
@property (nonatomic, weak) UIColor *backgroundColor;
- (IBAction)done:(id)sender;

@end


@protocol BacklightViewControllerDelegate
- (void)backlightViewControllerDidFinish:(BacklightViewController *)controller;
@end
