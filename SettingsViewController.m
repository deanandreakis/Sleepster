//
//  SettingsViewController.m
//  SleepMate
//
//  Created by Dean Andreakis on 12/6/12.
//
//

#import "SettingsViewController.h"
#import "Constants.h"
#import "SleepsterIAPHelper.h"
#import <StoreKit/StoreKit.h>
#import "TimerViewController.h"

@interface SettingsViewController () {
    NSArray *_products;
    NSNumberFormatter * _priceFormatter;
    SKProduct* _bgProduct;
    SKProduct* _soundProduct;
}

@property (strong, nonatomic) IBOutlet UISwitch *bgSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *soundSwitch;
@property (strong, nonatomic) UIActivityIndicatorView* activityIndicatorView;
@property (strong, nonatomic) UIAlertController* pleaseWaitAlertController;
@property (strong, nonatomic) IBOutlet UIButton* restoreButton;
@property (strong, nonatomic) IBOutlet UILabel* restoreLabel;
@property (strong, nonatomic) TimerViewController* timerController;
@property (strong, nonatomic) IBOutlet UILabel* timerLabel;
@property (strong, nonatomic) IBOutlet UILabel* minutesLabel;
@end

@implementation SettingsViewController

@synthesize timerController, bgSwitch, soundSwitch, activityIndicatorView;
@synthesize pleaseWaitAlertController,restoreButton,restoreLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    pleaseWaitAlertController = [UIAlertController alertControllerWithTitle:nil
                                                                    message:@"Please wait...\n\n\n"
                                                             preferredStyle:UIAlertControllerStyleAlert];
    activityIndicatorView.color = [UIColor blueColor];
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [pleaseWaitAlertController.view addSubview:activityIndicatorView];
    
    [pleaseWaitAlertController.view addConstraints:@[
                                     [NSLayoutConstraint constraintWithItem:activityIndicatorView
                                                                  attribute:NSLayoutAttributeCenterX
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:pleaseWaitAlertController.view
                                                                  attribute:NSLayoutAttributeCenterX
                                                                 multiplier:1 constant:0],
                                     [NSLayoutConstraint constraintWithItem:activityIndicatorView
                                                                  attribute:NSLayoutAttributeCenterY
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:pleaseWaitAlertController.view
                                                                  attribute:NSLayoutAttributeCenterY
                                                                 multiplier:1 constant:0]
                                     ]];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _priceFormatter = [[NSNumberFormatter alloc] init];
    [_priceFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    self.timerLabel.text = @"OFF";
    self.minutesLabel.hidden = YES;
    
    timerController = [[TimerViewController alloc] initWithNibName:@"TimerViewController" bundle:nil];
    timerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    timerController.restorationIdentifier = RESTORATION_ID_TIMER_VC;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveTimerNotification2:)
                                                 name:@"TIMER_NOTIFICATION"
                                               object:nil];
    
    [self getProducts];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionFailed:) name:IAPHelperTransactionFailedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IAPHelperProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IAPHelperTransactionFailedNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc
{
    // If you don't remove yourself as an observer, the Notification Center
    // will continue to try and send notification objects to the deallocated
    // object.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name: @"TIMER_NOTIFICATION"
                                                  object:nil];
}

#pragma mark IAP
//called when transaction is completed and successfully purchased or restored.
- (void)productPurchased:(NSNotification *)notification {
    
    NSString * productIdentifier = notification.object;
    
    [activityIndicatorView stopAnimating];
    [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    
    if([productIdentifier isEqualToString:STOREKIT_PRODUCT_ID_BACKGROUNDS]) {
        [bgSwitch setOn:YES animated:YES];//turn the switch on
    }
    else if([productIdentifier isEqualToString:STOREKIT_PRODUCT_ID_SOUNDS]) {
        [soundSwitch setOn:YES animated:YES];//turn the switch on
    }
    
}

- (void)transactionFailed:(NSNotification *)notification {
    NSString * productIdentifier = notification.object;
    
    [activityIndicatorView stopAnimating];
    [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    
    if([productIdentifier isEqualToString:STOREKIT_PRODUCT_ID_BACKGROUNDS]) {
        [bgSwitch setOn:NO animated:YES];//turn the switch off
    }
    else if([productIdentifier isEqualToString:STOREKIT_PRODUCT_ID_SOUNDS]) {
        [soundSwitch setOn:NO animated:YES];//turn the switch off
    }
}

- (void)getProducts {
    _products = nil;
    _bgProduct = nil;
    _soundProduct = nil;
    
    [[SleepsterIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success) {
            _products = products;
            for (SKProduct* product in _products) {
                if([product.productIdentifier isEqualToString:STOREKIT_PRODUCT_ID_BACKGROUNDS]) {
                    _bgProduct = product;
                }
                else if([product.productIdentifier isEqualToString:STOREKIT_PRODUCT_ID_SOUNDS]) {
                    _soundProduct = product;
                }
            }
            //NSLog(@"IAP Response: %@", _products);
        } else {
            //leave the _bgProduct and _soundProduct nil
        }
    }];
}

#pragma mark sound and background values

-(IBAction)soundMixSwitch:(id)sender
{
    //[Flurry logEvent:@"Sound Mix Switch Selected"];
    UISwitch* switcher = (UISwitch *)sender;
    if([switcher isOn])//switch changed to on
    {
        if(_soundProduct != nil) {
            if (![[SleepsterIAPHelper sharedInstance] productPurchased:_soundProduct.productIdentifier]) { //have not purchased product
                if ([SKPaymentQueue canMakePayments]) { //make sure they are allowed to perform IAP per parental controls settings
                    
                    [_priceFormatter setLocale:_soundProduct.priceLocale];
                    
                    NSMutableString* myString = [[NSMutableString alloc] initWithCapacity:25];
                    [myString appendString:_soundProduct.localizedTitle];
                    [myString appendString:@": "];
                    [myString appendString:_soundProduct.localizedDescription];
                    [myString appendString:@"\n"];
                    [myString appendString:NSLocalizedString(@"Price: ",nil)];
                    [myString appendString:[_priceFormatter stringFromNumber:_soundProduct.price]];
                    
                    UIAlertController *alertController = [UIAlertController
                                                          alertControllerWithTitle:NSLocalizedString(@"Confirm Purchase of the Multiple Sounds Feature",nil)
                                                          message:myString
                                                          preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction
                                                   actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                                   style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *action)
                                                   {
                                                       [soundSwitch setOn:NO animated:YES];//turn the switch off
                                                   }];
                    
                    UIAlertAction *buyAction = [UIAlertAction
                                                   actionWithTitle:NSLocalizedString(@"Buy",nil)
                                                   style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action)
                                                   {
                                                       [[SleepsterIAPHelper sharedInstance] buyProduct:_soundProduct];
                                                       [self presentViewController:pleaseWaitAlertController animated:NO completion:nil];
                                                       [activityIndicatorView startAnimating];
                                                   }];
                    
                    [alertController addAction:cancelAction];
                    [alertController addAction:buyAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                    
                } else {
                    UIAlertController *alertController = [UIAlertController
                                                          alertControllerWithTitle:NSLocalizedString(@"Prohibited",nil)
                                                          message:NSLocalizedString(@"This feature is available via In-App Purchase. Parental Control is enabled, cannot make a purchase!",nil)
                                                          preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *okAction = [UIAlertAction
                                                actionWithTitle:NSLocalizedString(@"Ok",nil)
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action)
                                                {
                                                    [soundSwitch setOn:NO animated:YES];//turn the switch off
                                                }];
                    
                    [alertController addAction:okAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                }
            }
        } else {
            //the products are nil so the original product fetch in getProducts() failed
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:NSLocalizedString(@"Product Not Available",nil)
                                                  message:NSLocalizedString(@"This product is not currently available. Please try again later.",nil)
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Ok",nil)
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           [soundSwitch setOn:NO animated:YES];//turn the switch off
                                       }];
            
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
    else{
        //NSLog(@"switch is OFF");
        [self.settingsDelegate settingsViewControllerSoundSwitchedOff];
    }
}

-(IBAction)backgroundMixSwitch:(id)sender
{
    //[Flurry logEvent:@"Background Mix Switch Selected"];
    UISwitch* switcher = (UISwitch *)sender;
    if([switcher isOn])//switch changed to on
    {
        if(_bgProduct != nil) {
            if (![[SleepsterIAPHelper sharedInstance] productPurchased:_bgProduct.productIdentifier]) { //have not purchased product
                 if ([SKPaymentQueue canMakePayments]) { //make sure they are allowed to perform IAP per parental controls settings
            
                     [_priceFormatter setLocale:_bgProduct.priceLocale];
                     
                     NSMutableString* myString = [[NSMutableString alloc] initWithCapacity:25];
                     [myString appendString:_bgProduct.localizedTitle];
                     [myString appendString:@": "];
                     [myString appendString:_bgProduct.localizedDescription];
                     [myString appendString:@"\n"];
                     [myString appendString:NSLocalizedString(@"Price: ",nil)];
                     [myString appendString:[_priceFormatter stringFromNumber:_bgProduct.price]];
            
                     UIAlertController *alertController = [UIAlertController
                                                           alertControllerWithTitle:NSLocalizedString(@"Confirm Purchase of the Rotate Backgrounds Feature",nil)
                                                           message:myString
                                                           preferredStyle:UIAlertControllerStyleAlert];
                     UIAlertAction *cancelAction = [UIAlertAction
                                                    actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                                    style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction *action)
                                                    {
                                                        [bgSwitch setOn:NO animated:YES];//turn the switch off
                                                    }];
                     
                     UIAlertAction *buyAction = [UIAlertAction
                                                 actionWithTitle:NSLocalizedString(@"Buy",nil)
                                                 style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action)
                                                 {
                                                     [[SleepsterIAPHelper sharedInstance] buyProduct:_bgProduct];
                                                     [self presentViewController:pleaseWaitAlertController animated:NO completion:nil];
                                                     [activityIndicatorView startAnimating];
                                                 }];
                     
                     [alertController addAction:cancelAction];
                     [alertController addAction:buyAction];
                     [self presentViewController:alertController animated:YES completion:nil];
                 } else {
                     
                     UIAlertController *alertController = [UIAlertController
                                                           alertControllerWithTitle:NSLocalizedString(@"Prohibited",nil)
                                                           message:NSLocalizedString(@"This feature is available via In-App Purchase. Parental Control is enabled, cannot make a purchase!",nil)
                                                           preferredStyle:UIAlertControllerStyleAlert];
                     UIAlertAction *okAction = [UIAlertAction
                                                actionWithTitle:NSLocalizedString(@"Ok",nil)
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action)
                                                {
                                                    [bgSwitch setOn:NO animated:YES];//turn the switch off
                                                }];
                     
                     [alertController addAction:okAction];
                     [self presentViewController:alertController animated:YES completion:nil];
                 }
            }
        } else {
            //the products are nil so the original product fetch in getProducts() failed
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:NSLocalizedString(@"Product Not Available",nil)
                                                  message:NSLocalizedString(@"This product is not currently available. Please try again later.",nil)
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Ok",nil)
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           [bgSwitch setOn:NO animated:YES];//turn the switch off
                                       }];
            
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
    else{
        //NSLog(@"switch is OFF");
        [self.settingsDelegate settingsViewControllerBgSwitchedOff];
    }
}

#pragma  mark Restore Button Action

-(IBAction)restoreSelected:(id)sender {
    [[SleepsterIAPHelper sharedInstance] restoreCompletedTransactions];
}

#pragma mark switch states

-(BOOL)bgSwitchState
{
    return [bgSwitch isOn];
}

-(BOOL)soundSwitchState
{
    return [soundSwitch isOn];
}

#pragma mark TimerViewControllerDelegate

- (void) receiveTimerNotification2:(NSNotification *) notification
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSString* string = (NSString*)[notification.userInfo objectForKey:@"timerstring"];
    
    self.timerLabel.text = string;
     if([string isEqualToString:NSLocalizedString(@"OFF",nil)])
     {
     self.minutesLabel.hidden = YES;
     }
     else
     {
     self.minutesLabel.hidden = NO;
     }
}

- (IBAction)timerButtonSelected:(id)sender
{
    [self presentViewController:timerController animated:YES completion:nil];
}


#pragma mark state preservation and restoration
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeBool:[self.bgSwitch isOn] forKey:@"bgSwitch"];
    [coder encodeBool:[self.soundSwitch isOn]forKey:@"soundSwitch"];
    
    //for a containing VC we just need to call encode on it to trigger
    //its encode/decode calls, so we dont need to decode it here
    [coder encodeObject:timerController forKey:@"TimerViewController"];
    
    [coder encodeObject:self.timerLabel.text forKey:@"timerLabel"];

}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    [self.bgSwitch setOn:[coder decodeBoolForKey:@"bgSwitch"]];
    [self.soundSwitch setOn:[coder decodeBoolForKey:@"soundSwitch"]];
    
    self.timerLabel.text = [coder decodeObjectForKey:@"timerLabel"];
    if([self.timerLabel.text isEqualToString:NSLocalizedString(@"OFF",nil)])
     {
     self.minutesLabel.hidden = YES;
     }
     else
     {
     self.minutesLabel.hidden = NO;
     }
}

@end
