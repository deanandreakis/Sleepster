//
//  SoundsViewController.h
//  SleepMate
//
//  Created by Dean Andreakis on 12/9/12.
//
// Use UICollectionView per http://www.raywenderlich.com/22324/beginning-uicollectionview-in-ios-6-part-12

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol SoundsViewControllerDelegate <NSObject>
- (void)songSelected:(AVAudioPlayer*)song;
@end

@interface SoundsViewController : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property(assign) id<SoundsViewControllerDelegate> delegate;

@end
