//
//  FlickrAPIClient.h
//
//
//  Created by Dean Andreakis on 07/19/13.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface FlickrAPIClient : AFHTTPClient

+ (id)sharedAPIClient;

@end
