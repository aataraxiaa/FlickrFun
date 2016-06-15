//
//  FlickrTableViewController.m
//  FlickrFun
//
//  Created by Pete on 16/10/2014.
//  Copyright (c) 2014 Soundwave. All rights reserved.
//

#import "FlickrTableViewController.h"
#import "FlickrFetcher.h"
#import "FlickrUITableViewCell.h"
#import "FlickrPhotoViewController.h"
#import "NSURLSession+SharedSession.h"
//#import <AFNetworking/AFNetworking.h>
#import "UIImageView+AFNetworking.h"

//STRING CONSTANTS
static NSString *const FLICKRTABLECELLNREUSEIDENTIFIER = @"flickrTableReuseIdentifier";
static NSString *const FLICKRTABLECELLNAME = @"FlickrUITableViewCell";
static NSString *const GETTINGLATESTPHOTOS = @"Getting latest photos...";
static NSString *const NOPHOTOSAVAILABLE = @"No photos available. Pull down to refresh.";
static NSString *const TITLEUNKNOWN = @"Title Unknown";
static NSString *const MIMETYPEJPEG = @"image/jpeg";
static NSString *const SEQUEIDENTIFIER = @"showFlickrPhotoView";
static NSString *const FONTCOPPERPLATE = @"Copperplate";
static int const ZERO = 0;
static int const ONE = 1;

@interface FlickrTableViewController ()

@property (strong, nonatomic) NSMutableArray *latestFlickrPhotos;
@property (strong, nonatomic) NSDictionary *selectedPhotoDictionary;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation FlickrTableViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Register our custom cell nib
    [self.tableView registerNib:[UINib nibWithNibName:FLICKRTABLECELLNAME bundle:nil] forCellReuseIdentifier:FLICKRTABLECELLNREUSEIDENTIFIER];
    
    //Set refresh control action
    [self.refreshControl addTarget:self
                            action:@selector(refreshPhotoList)
                  forControlEvents:UIControlEventValueChanged];
    
    //Show activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:self.view.bounds];
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    self.activityIndicator.hidesWhenStopped = YES;
    [self.activityIndicator startAnimating];
    self.tableView.backgroundView = self.activityIndicator;
    
    //Disable tableview interaction while we get the inital list of photos
    [self.tableView setUserInteractionEnabled:NO];
    
    //Perform the initial photo retrieval on the glonal concurrent queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, ZERO), ^{
        [self getLatestPhotos];
        
        //Once we have the initial list of latest photos, perform the necessary table reload on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            [self.tableView setUserInteractionEnabled:YES];
            [self.tableView reloadData];
        });
    });
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Custom Methods
- (void)getLatestPhotos {
    //Get photo list
    self.latestFlickrPhotos = [[FlickrFetcher latestPhotos] mutableCopy];
    
    //Sort photo List
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:FLICKR_PHOTO_DATE_UPLOAD  ascending:YES];
    NSArray *sortedPhotos = [self.latestFlickrPhotos sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    self.latestFlickrPhotos = [sortedPhotos copy];
}

- (void)refreshPhotoList {
    //Get the list and set the title for the refresh control
    [self getLatestPhotos];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc]
                                           initWithString:GETTINGLATESTPHOTOS
                                           attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];

    [self.refreshControl endRefreshing];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (self.latestFlickrPhotos) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        if(self.activityIndicator.isAnimating) {
            [self viewWillAppear:NO];
        }
        return ONE;
    } else if(self.activityIndicator.isAnimating) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        return ZERO;
    } else {
        //If the list of photos is empty, display a UiLabel message
        NSLog(@"Error retrieving photos");
        UILabel *noPhotosLabel = [[UILabel alloc] initWithFrame:CGRectMake(ZERO, ZERO, self.view.bounds.size.width, self.view.bounds.size.height)];
        noPhotosLabel.text = NOPHOTOSAVAILABLE;
        noPhotosLabel.textColor = [UIColor lightGrayColor];
        noPhotosLabel.numberOfLines = ZERO;
        noPhotosLabel.textAlignment = NSTextAlignmentCenter;
        noPhotosLabel.font = [UIFont fontWithName:FONTCOPPERPLATE size:12];
        [noPhotosLabel sizeToFit];
        
        //Set the background view to the UILabel
        self.tableView.backgroundView = noPhotosLabel;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        return ZERO;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    //Number of rows is equal to the number of photos in the latestFlickrPhotos array
    if (self.latestFlickrPhotos) {
        return [self.latestFlickrPhotos count];
    } else {
        return ONE;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *photoDict = self.latestFlickrPhotos[indexPath.row];
    FlickrUITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FLICKRTABLECELLNREUSEIDENTIFIER forIndexPath:indexPath];
    
    //Nil image from reused cell
    cell.thumbnailImageView.image = nil;
   
    //Cell Title
    NSString *imageTitle = [photoDict valueForKey:FLICKR_PHOTO_TITLE];
    if ([imageTitle length]) {
        cell.imageTitle.text = imageTitle;
    } else {
        cell.imageTitle.text = TITLEUNKNOWN;
    }
    
    //Create an image details string, and add it to the dictionary here.
    //This means we won't need to do this every time we call cellForRow...
    if (![photoDict objectForKey:FLICKR_PHOTO_DETAILS]) {
        //Upload Timestamp
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[photoDict valueForKey:FLICKR_PHOTO_DATE_UPLOAD] intValue]];
        NSString *formattedUploadData = [dateFormatter stringFromDate:date];
        
        //Image description
        NSString *imageDescription;
        if ([[photoDict valueForKeyPath:FLICKR_PHOTO_DESCRIPTION] length]) {
            imageDescription = [photoDict valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
        }
        
        NSString *imageDetails;
        if (imageDescription) {
            imageDetails = [NSString stringWithFormat:@"%@, %@", formattedUploadData, imageDescription];
        } else {
            imageDetails = formattedUploadData;
        }
        
        [photoDict setObject:imageDetails forKey:FLICKR_PHOTO_DETAILS];
        cell.imageDetails.text = imageDetails;
    } else {
         cell.imageDetails.text = [photoDict objectForKey:FLICKR_PHOTO_DETAILS];
    }
    
    //Get the flickr image thumbnail (Image will be loaded from cache if it was previously retrieved from URL)
    NSURL *imageUrl = [FlickrFetcher urlForPhoto:self.latestFlickrPhotos[indexPath.row] format:FlickrPhotoFormatSquare];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:imageUrl];
    UIImage *placeholderImage = [UIImage imageNamed:@"FlickrPlaceHolder"];
    
    __weak FlickrUITableViewCell *weakCell = cell;
    
    [cell.thumbnailImageView setImageWithURLRequest:request
                          placeholderImage:placeholderImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       
                                       weakCell.thumbnailImageView.image = image;
                                       [weakCell setNeedsLayout];
                                       
                                   } failure:nil];
    return cell;
}

#pragma mark - Table view data source
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedPhotoDictionary = self.latestFlickrPhotos[indexPath.row];
    [self performSegueWithIdentifier:SEQUEIDENTIFIER sender:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Pass the selected cells associated photos dictionary to the FlickrPhotoViewController
    ((FlickrPhotoViewController *)[segue destinationViewController]).photoDictionary = self.selectedPhotoDictionary;
}

@end
