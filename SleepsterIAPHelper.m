//
//  SleepsterIAPHelper.m
//  SleepMate
//
//  Created by Dean Andreakis on 9/17/13.
//
//

#import "SleepsterIAPHelper.h"
#import "Constants.h"

@implementation SleepsterIAPHelper

+ (SleepsterIAPHelper *)sharedInstance {
    static dispatch_once_t once;
    static SleepsterIAPHelper * sharedInstance;
    dispatch_once(&once, ^{
        NSSet * productIdentifiers = [NSSet setWithObjects:
                                      STOREKIT_PRODUCT_ID_BACKGROUNDS,
                                      STOREKIT_PRODUCT_ID_SOUNDS,
                                      nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

@end
