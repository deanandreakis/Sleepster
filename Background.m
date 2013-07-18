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

@implementation Background

@dynamic bTitle;
@dynamic bFullSizeUrl;
@dynamic bThumbnailUrl;
@dynamic isImage;
@dynamic isFavorite;
@dynamic bColor;

//params
//&api_key=6dbd76ac76dcb9f495b15ed1caddd80a&tags=ocean%2Criver%2Ccrickets&privacy_filter=1&group_id=11011571%40N00&format=json&nojsoncallback=1

+ (void)fetchPics:(PicsBlock)block {
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            FLICKR_API_KEY, @"api_key",
                            @"ocean", @"tags",
                            @"1", @"privacy_filter",
                            @"11011571@N00", @"group_id",
                            @"json", @"format",
                            @"1", @"nojsoncallback",
                            nil];
    
    [[FlickrAPIClient sharedAPIClient] getPath:@"?method=flickr.photos.search"
                                       parameters:params
                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                              NSLog(@"Response: %@", responseObject);
                                              NSMutableArray *results = [NSMutableArray array];
                                              for (id picDictionary in responseObject[@"photo"]) {
                                                  Background *background = [Background postWithDictionary:picDictionary];
                                                  [results addObject:background];
                                              }
                                              if (block)
                                                  block(results);
                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              NSLog(@"HTTP Status %d", operation.response.statusCode);
                                              NSLog(@"ERROR: %@", error);
                                              
                                              if (block)
                                                  block(nil);
                                          }];
}

+ (id)postWithDictionary:(NSDictionary *)dictionary {
    Background *background = [[Background alloc] init];
    background.bTitle = dictionary[@"title"];
    background.isImage = @YES;
    background.isFavorite = @NO;
    background.bColor = nil;
    background.bThumbnailUrl = [Background createThumbnailUrl:dictionary];
    background.bFullSizeUrl = [Background createFullSizeUrl:dictionary];
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
