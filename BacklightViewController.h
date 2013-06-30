//
//  BacklightViewController.h
//  iSleep
//
//  Created by Dean Andreakis on 6/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

@protocol BacklightViewControllerDelegate;


@interface BacklightViewController : UIViewController {
}

@property (nonatomic, strong) id <BacklightViewControllerDelegate> bgDelegate;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic) float brightness;
- (IBAction)done:(id)sender;

@end


@protocol BacklightViewControllerDelegate
- (void)backlightViewControllerDidFinish:(BacklightViewController *)controller;
@end
