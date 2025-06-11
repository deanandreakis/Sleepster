//
//  Background.m
//  SleepMate
//
//  Created by Dean Andreakis on 7/18/13.
//
//

#import "Background.h"
#import "FlickrAPIClient.h"
#import "Constants.h"
#import "DatabaseManager.h"

@implementation Background

@dynamic bTitle;
@dynamic bFullSizeUrl;
@dynamic bThumbnailUrl;
@dynamic isImage;
@dynamic isLocalImage;
@dynamic isFavorite;
@dynamic isSelected;
@dynamic bColor;

//params
//&api_key=6dbd76ac76dcb9f495b15ed1caddd80a&tags=ocean%2Criver%2Ccrickets&privacy_filter=1&group_id=11011571%40N00&format=json&nojsoncallback=1

//http://www.flickr.com/services/api/flickr.photos.search.html

+ (void)fetchPics:(PicsBlock)block withSearchTags:(NSString *)searchTags{
    // Legacy AFNetworking implementation - replaced by SwiftUI FlickrService
    // All Flickr functionality now handled by modern SwiftUI BackgroundsViewModel
    NSLog(@"Legacy fetchPics called - returning empty results. Use SwiftUI BackgroundsView instead.");
    
    // Return empty results to prevent crashes
    if (block) {
        block(@[]);
    }
    
    /*
    // Legacy AFNetworking code - commented out
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            FLICKR_API_KEY, @"api_key",
                            searchTags, @"tags",
                            @"1", @"privacy_filter",
                            @"11011571@N00", @"group_id",
                            @"json", @"format",
                            @"1", @"nojsoncallback",
                            nil];
    
    [[FlickrAPIClient sharedAPIClient] getPath:@"?method=flickr.photos.search"
                                       parameters:params
                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                              // ... legacy implementation
                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              // ... legacy implementation
                                          }];
    */
}

+ (id)postWithDictionary:(NSDictionary *)dictionary {
    NSManagedObjectContext *context = [[DatabaseManager sharedDatabaseManager] managedObjectContext];
    Background *background = [NSEntityDescription insertNewObjectForEntityForName:@"Background"
                                                           inManagedObjectContext:context];
    [context performBlockAndWait:^{
    
    background.bTitle = dictionary[@"title"];
    background.isImage = @YES;
    background.isLocalImage = @NO;
    background.isFavorite = @NO;
    background.isSelected = @NO;
    background.bColor = nil;
    background.bThumbnailUrl = [Background createThumbnailUrl:dictionary];
    background.bFullSizeUrl = [Background createFullSizeUrl:dictionary];
    NSError *error;
    if (![context save:&error]) {
        //NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    }];
    return background;
}

+ (NSString*)createThumbnailUrl:(NSDictionary *)dictionary {
    //http://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}_[mstzb].jpg
    NSString* retVal = nil;
    NSMutableString* tempString = [NSMutableString stringWithCapacity:20];
    [tempString appendFormat:@"http://farm%@.staticflickr.com/%@/%@_%@_t.jpg",
     dictionary[@"farm"], dictionary[@"server"],dictionary[@"id"],dictionary[@"secret"]];
    retVal = tempString;
    return retVal;
}

+ (NSString*)createFullSizeUrl:(NSDictionary *)dictionary {
    //http://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}_[mstzb].jpg
    NSString* retVal = nil;
    NSMutableString* tempString = [NSMutableString stringWithCapacity:20];
    [tempString appendFormat:@"http://farm%@.staticflickr.com/%@/%@_%@_z.jpg",
     dictionary[@"farm"], dictionary[@"server"],dictionary[@"id"],dictionary[@"secret"]];
    retVal = tempString;
    return retVal;
}

@end
