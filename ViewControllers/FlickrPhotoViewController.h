//
//  FlickrPhotoViewController.h
//  FlickrFun
//
//  Created by Pete on 17/10/2014.
//  Copyright (c) 2014 Soundwave. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlickrPhotoViewController : UIViewController <UIPopoverControllerDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) NSDictionary *photoDictionary;

@end
