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
    static FlickrAPIClient *__client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseURL = [NSURL URLWithString:kFlickrBaseUrl];
        __client = [[FlickrAPIClient alloc] initWithBaseURL:baseURL];
    });
    return __client;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/json"];
        self.allowsInvalidSSLCertificate = YES; //this defaults to no
    }
    
    return self;
}

@end


















/*
 [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
 [self setDefaultHeader:@"Accept" value:@"application/json"];
*/