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

#define ALERTVIEW_BG_BUY 0
#define ALERTVIEW_BG_IAP_DISABLED 1

@interface SettingsViewController () {
    NSArray *_products;
    NSNumberFormatter * _priceFormatter;
    SKProduct* _bgProduct;
    SKProduct* _soundProduct;
}

@property (strong, nonatomic) IBOutlet UISwitch *bgSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *soundSwitch;

@end

@implementation SettingsViewController

@synthesize bgSwitch, soundSwitch;

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
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    _priceFormatter = [[NSNumberFormatter alloc] init];
    [_priceFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    [self getProducts];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark IAP
//called when transaction is completed and successfully purchased or restored.
- (void)productPurchased:(NSNotification *)notification {
    
    NSString * productIdentifier = notification.object;
    
    //TODO: remove alert on the screen or stop spinner, put switch in on state
    
    [_products enumerateObjectsUsingBlock:^(SKProduct * product, NSUInteger idx, BOOL *stop) {
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            //[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            *stop = YES;
        }
    }];
    
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
                if([product.productIdentifier isEqualToString:STOREKIT_PRODUCT_ID_SOUNDS]) {
                    _soundProduct = product;
                }
            }
            NSLog(@"IAP Response: %@", _products);
        } else {
            //TODO: did not get products back!
        }
    }];
}

#pragma mark sound and background values

-(IBAction)soundMixSwitch:(id)sender
{
    //TODO: storekit logic
    UISwitch* switcher = (UISwitch *)sender;
    if([switcher isOn])
    {
        //NSLog(@"switch is ON");
    }
    else{
        //NSLog(@"switch is OFF");
        [self.settingsDelegate settingsViewControllerSoundSwitchedOff];
    }
}

-(IBAction)backgroundMixSwitch:(id)sender
{
    UISwitch* switcher = (UISwitch *)sender;
    if([switcher isOn])//switch changed to on
    {
        if (![[SleepsterIAPHelper sharedInstance] productPurchased:_bgProduct.productIdentifier]) { //have not purchased product
             if ([SKPaymentQueue canMakePayments]) { //make sure they are allowed to perform IAP per parental controls settings
        
                 [_priceFormatter setLocale:_bgProduct.priceLocale];
                 
                 NSMutableString* myString = [[NSMutableString alloc] initWithCapacity:25];
                 [myString appendString:_bgProduct.localizedTitle];
                 [myString appendString:@": "];
                 [myString appendString:_bgProduct.localizedDescription];
                 [myString appendString:@"\n"];
                 [myString appendString:@"Price: "];
                 [myString appendString:[_priceFormatter stringFromNumber:_bgProduct.price]];
        
                 UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Purchase the Rotate Backgrounds Feature?"
                                                                     message:myString
                                                                    delegate:self
                                                           cancelButtonTitle:@"Cancel"
                                                           otherButtonTitles:@"Buy", nil];
                 alertView.tag = ALERTVIEW_BG_BUY;
                 [alertView show];
                 
             } else {
                 //[switcher setOn:NO animated:YES];//turn the switch off...do this in the alertview delegate
                 
                 UIAlertView *tmp = [[UIAlertView alloc]
                                     
                                     initWithTitle:@"Prohibited"
                                     
                                     message:@"This feature is available via In-App Purchase. Parental Control is enabled, cannot make a purchase!"
                                     
                                     delegate:self
                                     
                                     cancelButtonTitle:nil
                                     
                                     otherButtonTitles:@"Ok", nil];
                 
                 tmp.tag = ALERTVIEW_BG_IAP_DISABLED;
                 
                 [tmp show];
             }
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
            if(buttonIndex == 0) {
                
            } else if(buttonIndex == 1) {
                [[SleepsterIAPHelper sharedInstance] buyProduct:_bgProduct];//TODO: some spinner here???
            }
            break;
        case ALERTVIEW_BG_IAP_DISABLED:
            break;
        default:
            break;
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

#pragma mark state preservation and restoration
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeBool:[self.bgSwitch isOn] forKey:@"bgSwitch"];
    [coder encodeBool:[self.soundSwitch isOn]forKey:@"soundSwitch"];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    [self.bgSwitch setOn:[coder decodeBoolForKey:@"bgSwitch"]];
    [self.soundSwitch setOn:[coder decodeBoolForKey:@"soundSwitch"]];
}

@end
