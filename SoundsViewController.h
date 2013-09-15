//
//  SoundsViewController.h
//  SleepMate
//
//  Created by Dean Andreakis on 12/9/12.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol SoundsViewControllerDelegate <NSObject>
- (void)songSelected:(AVAudioPlayer*)song;
- (void)songDeSelected:(AVAudioPlayer*)song;
@end

@interface SoundsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIDataSourceModelAssociation>

@property(assign) id<SoundsViewControllerDelegate> delegate;

@end
