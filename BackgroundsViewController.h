//
//  BackgroundsViewController.h
//  SleepMate
//
//  Created by Dean Andreakis on 12/9/12.
//
//http://www.raywenderlich.com/22324/beginning-uicollectionview-in-ios-6-part-12

#import <UIKit/UIKit.h>
#import "Background.h"

@protocol BackgroundsViewControllerDelegate <NSObject>
- (void)backgroundSelected:(Background*)background;
@end

@interface BackgroundsViewController : UICollectionViewController <NSFetchedResultsControllerDelegate,UICollectionViewDataSource, UICollectionViewDelegate>

@property(assign) id<BackgroundsViewControllerDelegate> delegate;

@end
