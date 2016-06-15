//
//  NSURLSessionConfiguration+SharedSession.m
//  FlickrFun
//
//  Created by Pete on 17/10/2014.
//  Copyright (c) 2014 Soundwave. All rights reserved.
//

#import "NSURLSession+SharedSession.h"

static int const kREQUEST_TIMEOUT = 15;

@implementation NSURLSession (SharedSession)

+ (NSURLSession *)sharedCustomSession {
    static NSURLSession *sharedSession = nil;
    
    //Creating a custom shared session (as opposed to the supplied shared singleton)
    //Purpose is to set the configuration values for cache, timeout etc.
    if (sharedSession == nil) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.URLCache = [NSURLCache sharedURLCache];
        config.timeoutIntervalForRequest = kREQUEST_TIMEOUT;
        
        /*As we will be performing UI-related tasks in the Session completion handler, we set the delegates queue
        to be the main queue*/
        sharedSession = [NSURLSession sessionWithConfiguration:config delegate:nil
                                                 delegateQueue:[NSOperationQueue mainQueue]];
    }
    return sharedSession;
}


@end
