//
//  TimerViewController.h
//  SleepMate
//
//  Created by Dean Andreakis on 7/10/13.
//
//

#import <UIKit/UIKit.h>

#define fadeoutTime 30

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

@end

