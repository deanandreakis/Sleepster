//
//  Sound.h
//  SleepMate
//
//  Created by Dean Andreakis on 9/2/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Sound : NSManagedObject

@property (nonatomic, retain) NSString * soundUrl1;
@property (nonatomic, retain) NSString * soundUrl2;
@property (nonatomic, retain) NSNumber * isSelected;
@property (nonatomic, retain) NSNumber * isFavorite;
@property (nonatomic, retain) NSString * bTitle;

@end
