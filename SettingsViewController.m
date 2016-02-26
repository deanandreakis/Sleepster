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
//#import "Flurry.h"

#define ALERTVIEW_BG_BUY 0
#define ALERTVIEW_BG_IAP_DISABLED 1
#define ALERTVIEW_BG_IAP_PRODUCT_NOT_AVAILABLE 2

#define ALERTVIEW_SOUND_IAP_DISABLED 4
#define ALERTVIEW_SOUND_IAP_PRODUCT_NOT_AVAILABLE 5

@interface SettingsViewController () {
    NSArray *_products;
    NSNumberFormatter * _priceFormatter;
    SKProduct* _bgProduct;
    SKProduct* _soundProduct;
}

@property (strong, nonatomic) IBOutlet UISwitch *bgSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *soundSwitch;
@property (strong, nonatomic) UIActivityIndicatorView* activityIndicatorView;
@property (strong, nonatomic) UIAlertView* pleaseWaitAlertView;
@property (strong, nonatomic) IBOutlet UIButton* restoreButton;
@property (strong, nonatomic) IBOutlet UILabel* restoreLabel;
@property (strong, nonatomic) TimerViewController* timerController;
@property (strong, nonatomic) IBOutlet UILabel* timerLabel;
@property (strong, nonatomic) IBOutlet UILabel* minutesLabel;
@end

@implementation SettingsViewController

@synthesize timerController, bgSwitch, soundSwitch, activityIndicatorView, pleaseWaitAlertView, restoreButton,restoreLabel;

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
    pleaseWaitAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Wait..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [self.view addSubview:pleaseWaitAlertView];
    [pleaseWaitAlertView addSubview:activityIndicatorView];
    activityIndicatorView.color = [UIColor blueColor];
    activityIndicatorView.center = CGPointMake(self.view.center.x, self.view.center.y + 35);
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _priceFormatter = [[NSNumberFormatter alloc] init];
    [_priceFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    if ([[UIScreen mainScreen] bounds].size.height == 568){
        //add your 4-inch specific code here
        restoreButton.frame = CGRectMake(118, 427, 84, 30);
        restoreLabel.frame = CGRectMake(40, 457, 255, 38);
    } else {
        restoreButton.frame = CGRectMake(118, 339, 84, 30);
        restoreLabel.frame = CGRectMake(40, 369, 255, 38);
    }
    
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
    
    //[Flurry logEvent:@"Entered Settings Screen"];
}

- (void)viewWillDisappear:(BOOL)animated {
    //[[NSNotificationCenter defaultCenter] removeObserver:self];//THE PROBLEM!!!!
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
    [pleaseWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
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
    [pleaseWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
    if([productIdentifier isEqualToString:STOREKIT_PRODUCT_ID_BACKGROUNDS]) {
        [bgSwitch setOn:NO animated:YES];//turn the switch off
    }
    else if([productIdentifier isEqualToString:STOREKIT_PRODUCT_ID_SOUNDS]) {
        [soundSwitch setOn:NO animated:YES];//turn the switch off
    }
    
    /*UIAlertView *tmp = [[UIAlertView alloc]
                        
                        initWithTitle:NSLocalizedString(@"Transaction Failed",nil)
                        
                        message:NSLocalizedString(@"The payment transaction failed. Please try again later.",nil)
                        
                        delegate:nil
                        
                        cancelButtonTitle:nil
                        
                        otherButtonTitles:NSLocalizedString(@"Ok",nil), nil];
    
    [tmp show];*/
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
                                                       [pleaseWaitAlertView show];
                                                       [activityIndicatorView startAnimating];
                                                   }];
                    
                    [alertController addAction:cancelAction];
                    [alertController addAction:buyAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                    
                } else {
                    
                    UIAlertView *tmp = [[UIAlertView alloc]
                                        
                                        initWithTitle:NSLocalizedString(@"Prohibited",nil)
                                        
                                        message:NSLocalizedString(@"This feature is available via In-App Purchase. Parental Control is enabled, cannot make a purchase!",nil)
                                        
                                        delegate:self
                                        
                                        cancelButtonTitle:nil
                                        
                                        otherButtonTitles:NSLocalizedString(@"Ok",nil), nil];
                    
                    tmp.tag = ALERTVIEW_SOUND_IAP_DISABLED;
                    
                    [tmp show];
                }
            }
        } else {
            //the products are nil so the original product fetch in getProducts() failed
            UIAlertView *tmp = [[UIAlertView alloc]
                                
                                initWithTitle:NSLocalizedString(@"Product Not Available",nil)
                                
                                message:NSLocalizedString(@"This product is not currently available. Please try again later.",nil)
                                
                                delegate:self
                                
                                cancelButtonTitle:nil
                                
                                otherButtonTitles:NSLocalizedString(@"Ok",nil), nil];
            
            tmp.tag = ALERTVIEW_SOUND_IAP_PRODUCT_NOT_AVAILABLE;
            
            [tmp show];
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
            
                     UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirm Purchase of the Rotate Backgrounds Feature",nil)
                                                                         message:myString
                                                                        delegate:self
                                                               cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                               otherButtonTitles:NSLocalizedString(@"Buy",nil), nil];
                     alertView.tag = ALERTVIEW_BG_BUY;
                     [alertView show];
                     
                 } else {
                     
                     UIAlertView *tmp = [[UIAlertView alloc]
                                         
                                         initWithTitle:NSLocalizedString(@"Prohibited",nil)
                                         
                                         message:NSLocalizedString(@"This feature is available via In-App Purchase. Parental Control is enabled, cannot make a purchase!",nil)
                                         
                                         delegate:self
                                         
                                         cancelButtonTitle:nil
                                         
                                         otherButtonTitles:NSLocalizedString(@"Ok",nil), nil];
                     
                     tmp.tag = ALERTVIEW_BG_IAP_DISABLED;
                     
                     [tmp show];
                 }
            }
        } else {
            //the products are nil so the original product fetch in getProducts() failed
            UIAlertView *tmp = [[UIAlertView alloc]
                                
                                initWithTitle:NSLocalizedString(@"Product Not Available",nil)
                                
                                message:NSLocalizedString(@"This product is not currently available. Please try again later.",nil)
                                
                                delegate:self
                                
                                cancelButtonTitle:nil
                                
                                otherButtonTitles:NSLocalizedString(@"Ok",nil), nil];
            
            tmp.tag = ALERTVIEW_BG_IAP_PRODUCT_NOT_AVAILABLE;
            
            [tmp show];
        }
    }
    else{
        //NSLog(@"switch is OFF");
        [self.settingsDelegate settingsViewControllerBgSwitchedOff];
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case ALERTVIEW_BG_BUY:
            if(buttonIndex == 0) {//CANCEL
                [bgSwitch setOn:NO animated:YES];//turn the switch off
            } else if(buttonIndex == 1) { //BUY
                [[SleepsterIAPHelper sharedInstance] buyProduct:_bgProduct];
                [pleaseWaitAlertView show];
                [activityIndicatorView startAnimating];
            }
            break;
        case ALERTVIEW_BG_IAP_DISABLED:
            [bgSwitch setOn:NO animated:YES];//turn the switch off
            break;
        case ALERTVIEW_BG_IAP_PRODUCT_NOT_AVAILABLE:
            [bgSwitch setOn:NO animated:YES];//turn the switch off
            break;
        case ALERTVIEW_SOUND_IAP_DISABLED:
            [soundSwitch setOn:NO animated:YES];//turn the switch off
            break;
        case ALERTVIEW_SOUND_IAP_PRODUCT_NOT_AVAILABLE:
            [soundSwitch setOn:NO animated:YES];//turn the switch off
            break;
        default:
            break;
    }
    
}

#pragma  mark Restore Button Action

-(IBAction)restoreSelected:(id)sender {
    [[SleepsterIAPHelper sharedInstance] restoreCompletedTransactions];
    //[pleaseWaitAlertView show];
    //[activityIndicatorView startAnimating];
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
    
    //NSNumber* value = (NSNumber*)[notification.userInfo objectForKey:@"timeout"];
    //NSInteger timeValue = [value integerValue];
    
    NSString* string = (NSString*)[notification.userInfo objectForKey:@"timerstring"];
    
    //self.timeOut = timeValue;
    
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
