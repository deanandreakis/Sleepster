//
//  TimerViewController.m
//  SleepMate
//
//  Created by Dean Andreakis on 7/10/13.
//
//

#import "TimerViewController.h"

@interface TimerViewController ()

@property (strong, nonatomic) IBOutlet UIPickerView* pickerView;
@property (assign, nonatomic) NSInteger timeOut;
@property (strong, nonatomic) NSArray *minutesArray;
@property (strong, nonatomic) IBOutlet UILabel* minutesLabel;

@end

@implementation TimerViewController

@synthesize pickerView, timeOut, minutesArray, minutesLabel;

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
    pickerView.delegate = self;
    pickerView.dataSource = self;
    timeOut = 0;
    //self.minutesArray = [NSArray arrayWithObjects:@"\u221E", @"15", @"30", @"60", @"90", nil];
    self.minutesArray = [NSArray arrayWithObjects:NSLocalizedString(@"OFF",nil), @"15", @"30", @"60", @"90", nil];
    self.minutesLabel.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [minutesArray count];
}

#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [minutesArray objectAtIndex:row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 50;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return 320;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(row == 0)
    {
        self.minutesLabel.hidden = YES;
    }
    else
    {
        self.minutesLabel.hidden = NO;
    }
}


#pragma mark done button selected

-(IBAction)doneSelected:(id)sender
{
    NSInteger row;
    row = [self.pickerView selectedRowInComponent:0];
    //NSLog(@"Picker Selected Row: %d", row);
    switch (row) {
        case kFifteenMinSegmentIndex:
			timeOut = 900 - fadeoutTime;//seconds
			break;
		case kThirtyMinSegmentIndex:
			timeOut = 1800 - fadeoutTime;//seconds
			break;
		case kSixtyMinSegmentIndex:
			timeOut = 3600 - fadeoutTime;//seconds
			break;
		case kNinetyMinSegmentIndex:
			timeOut = 5400 - fadeoutTime;//seconds
			break;
        case kOffSegmentIndex:
			timeOut = kOffSegmentIndex;//seconds
			break;
		default:
			timeOut = kOffSegmentIndex;
			break;
    }
    //since we have 2 objects that need to know this information lets use NSNotifications instead of the delegate pattern
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:timeOut], @"timeout",
                          [self.minutesArray objectAtIndex:row], @"timerstring",nil];
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TIMER_NOTIFICATION" object:nil userInfo:dict];
        });
}
     
#pragma mark state preservation and restoration
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    //NSLog(@"TIMER VC ENCODE");
    NSInteger row = [self.pickerView selectedRowInComponent:0];
    [coder encodeInteger:row forKey:@"tvc_row"];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    //NSLog(@"TIMER VC DECODE");
    NSInteger row = [coder decodeIntegerForKey:@"tvc_row"];
    [pickerView selectRow:row inComponent:0 animated:NO];
    [self pickerView:pickerView didSelectRow:row inComponent:0];
    [self doneSelected:nil];
}

@end
