//
//  FlickrAPIClient.m
//
//
//  Created by Dean Andreakis on 07/19/13.
//
//

#import "FlickrAPIClient.h"


#define kFlickrBaseUrl @"https://api.flickr.com/services/rest/"

@implementation FlickrAPIClient

+ (id)sharedAPIClient {
    // Legacy implementation - now replaced by Swift FlickrService
    return nil;
}

/*
// Legacy AFNetworking implementation - replaced by Swift FlickrService
- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/json"];
        self.allowsInvalidSSLCertificate = YES; //this defaults to no
    }
    
    return self;
}
*/

@end


















/*
 [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
 [self setDefaultHeader:@"Accept" value:@"application/json"];
*/