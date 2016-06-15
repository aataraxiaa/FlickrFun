//
//  FlickrUITableViewCell.h
//  FlickrFun
//
//  Created by Pete on 16/10/2014.
//  Copyright (c) 2014 Soundwave. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlickrUITableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *imageTitle;
@property (weak, nonatomic) IBOutlet UILabel *imageDetails;
@property (weak, nonatomic) IBOutlet UILabel *imageDateTime;

@end
