//
//  FlickrAPIClient.h
//
//
//  Created by Dean Andreakis on 07/19/13.
//

#import <Foundation/Foundation.h>
// Legacy AFNetworking implementation - replaced by Swift FlickrService
// #import "AFNetworking.h"

// Legacy class - replaced by Swift FlickrService in ViewModels
@interface FlickrAPIClient : NSObject // AFHTTPClient

+ (id)sharedAPIClient;

@end
