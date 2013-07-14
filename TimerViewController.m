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

@end

@implementation TimerViewController

@synthesize pickerView, timeOut, timerDelegate, minutesArray;

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
    self.minutesArray = [NSArray arrayWithObjects:@"\u221E", @"15", @"30", @"60", @"90", nil];
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
}


#pragma mark done button selected

-(IBAction)doneSelected:(id)sender
{
    NSInteger row;
    row = [self.pickerView selectedRowInComponent:0];
    NSLog(@"Picker Selected Row: %d", row);
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
    [self.timerDelegate timerViewControllerDidFinish:timeOut timerString:[self.minutesArray objectAtIndex:row]];
}


@end
