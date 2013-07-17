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

#define reviewString @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=417667154"

@interface InformationViewController ()

@property (strong, nonatomic) UIButton *menuBtn;
- (IBAction)tweeterButton:(id)sender;
- (IBAction)facebookButton:(id)sender;

@end

@implementation InformationViewController


@synthesize menuBtn;

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
    NSString * theUrl = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=417667154&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:theUrl]];
}

#pragma mark Social Network Methods

- (IBAction) tweeterButton:(id)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:NSLocalizedString(@"I'm using Sleepster and it puts me to sleep! :) http://tr.im/478gg", nil)];
        [self presentViewController:tweetSheet animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Sorry", nil)
                                  message:NSLocalizedString(@"tweetfail", nil)
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (IBAction) facebookButton:(id)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *fbSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [fbSheet setInitialText:NSLocalizedString(@"I'm using Sleepster and it puts me to sleep! :) http://tr.im/478gg", nil)];
        [self presentViewController:fbSheet animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Sorry", nil)
                                  message:NSLocalizedString(@"fbfail", nil)
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

@end
