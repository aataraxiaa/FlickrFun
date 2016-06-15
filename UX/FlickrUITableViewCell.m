//
//  FlickrUITableViewCell.m
//  FlickrFun
//
//  Created by Pete on 16/10/2014.
//  Copyright (c) 2014 Soundwave. All rights reserved.
//

#import "FlickrUITableViewCell.h"

@implementation FlickrUITableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    //Set custom cell selection color to match color theme of app
    UIImageView *bgView = [[UIImageView alloc]initWithFrame:self.frame];
    bgView.backgroundColor = [UIColor colorWithRed:109.0f/255 green:184.0/255 blue:226.0/255 alpha:0.4];
    self.selectedBackgroundView = bgView;
}

@end
