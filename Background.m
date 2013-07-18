//
//  Background.m
//  SleepMate
//
//  Created by Dean Andreakis on 7/18/13.
//
//

#import "Background.h"
#import "FlickrAPIClient.h"


@implementation Background

@dynamic bTitle;
@dynamic bFullSizeUrl;
@dynamic bThumbnailUrl;
@dynamic isImage;
@dynamic isFavorite;
@dynamic bColor;

+ (void)fetchPics:(PicsBlock)block {
    // endpoint is at /stream/0/posts/stream/global
    [[FlickrAPIClient sharedAPIClient] getPath:@"/stream/0/posts/stream/global"
                                       parameters:nil
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
    //post.author = dictionary[@"user"][@"username"];
    //post.avatarUrl = dictionary[@"user"][@"avatar_image"][@"url"];
    
    return background;
}

+ (NSString*)createThumbnailUrl:(NSDictionary *)dictionary {
    
}

+ (NSString*)createFullSizeUrl:(NSDictionary *)dictionary {
    
}

@end
