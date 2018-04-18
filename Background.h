//
//  Background.h
//  SleepMate
//
//  Created by Dean Andreakis on 7/18/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef void (^PicsBlock)(NSArray *pics);

@interface Background : NSManagedObject

@property (nonatomic, retain) NSString * bTitle;
@property (nonatomic, retain) NSString * bFullSizeUrl;
@property (nonatomic, retain) NSString * bThumbnailUrl;
@property (nonatomic, retain) NSNumber * isImage;
@property (nonatomic, retain) NSNumber * isFavorite;
@property (nonatomic, retain) NSNumber * isSelected;
@property (nonatomic, retain) NSNumber * isLocalImage;
@property (nonatomic, retain) NSString * bColor;

+ (void)fetchPics:(PicsBlock)block withSearchTags:(NSString *)searchTags;

@end
