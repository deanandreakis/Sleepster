//
//  TimerViewController.h
//  SleepMate
//
//  Created by Dean Andreakis on 7/10/13.
//
//

#import <UIKit/UIKit.h>

#define fadeoutTime 30

@protocol TimerViewControllerDelegate
- (void)timerViewControllerDidFinish:(NSInteger)timeValue timerString:(NSString*)string;
@end

@interface TimerViewController : UIViewController  <UIPickerViewDataSource, UIPickerViewDelegate>
{
    enum{
		kOffSegmentIndex = 0,
		kFifteenMinSegmentIndex,
		kThirtyMinSegmentIndex,
		kSixtyMinSegmentIndex,
		kNinetyMinSegmentIndex
	} kSegment;
}

@property (nonatomic, strong) id <TimerViewControllerDelegate> timerDelegate;

@end

