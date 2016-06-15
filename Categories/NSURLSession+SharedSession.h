//
//  NSURLSessionConfiguration+SharedSession.h
//  FlickrFun
//
//  Created by Pete on 17/10/2014.
//  Copyright (c) 2014 Soundwave. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SHARED_URL_SESSION @"sharedURLSession"

@interface NSURLSession (SharedSession)

+ (NSURLSession *)sharedCustomSession;

@end
