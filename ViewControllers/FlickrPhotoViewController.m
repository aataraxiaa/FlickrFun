//
//  FlickrPhotoViewController.m
//  FlickrFun
//
//  Created by Pete on 17/10/2014.
//  Copyright (c) 2014 Soundwave. All rights reserved.
//

#import "FlickrPhotoViewController.h"
#import "FlickrFetcher.h"
#import "NSURLSession+SharedSession.h"

//CONSTANTS
static NSString *const MIMETYPEJPEG = @"image/jpeg";
static NSString *const PHOTONOTAVAILABLE = @"Photo not available.";
static NSString *const FONTCOPPERPLATE = @"Copperplate";
static float const ZERO = 0.0f;
static int const DOUBLETAP = 2;
static float const MAXZOOM = 1.0f;
static float const FASTANIMATION = 0.2f;

@interface FlickrPhotoViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UIImage *flickrImage;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (nonatomic) BOOL returnedFromActivityView;

@end

@implementation FlickrPhotoViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    //Initially disable the share button
    [self.shareButton setEnabled:NO];
    
    //Customise view
    self.view.backgroundColor = [UIColor blackColor];
    
    //Init gesture recogniser
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewDoubleTapped:)];
    self.tapGesture.numberOfTapsRequired = DOUBLETAP;
    [self.view addGestureRecognizer:self.tapGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //If we are simply returning from the UIActivityView, DO NOT fetch image and set up subviews
    if (!self.returnedFromActivityView) {
        //Start network spinner
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        //Show activity indicator
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:self.view.bounds];
        self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        self.activityIndicator.hidesWhenStopped = YES;
        [self.activityIndicator startAnimating];
        [self.view addSubview:self.activityIndicator];
        
        
        //Get the full-size/larger image
        NSURL *imageURL = [FlickrFetcher urlForPhoto:self.photoDictionary format:FlickrPhotoFormatLarge];
        NSLog(@"Getting image from: %@", imageURL);
        NSURLSessionDataTask *dataTask = [[NSURLSession sharedCustomSession]
                                          dataTaskWithURL:imageURL
                                          completionHandler:^(NSData *data, NSURLResponse *response,
                                                              NSError *error) {
                                              if (!error && [response.MIMEType isEqualToString:MIMETYPEJPEG]) {
                                                  //Set the image
                                                  self.flickrImage = [[UIImage alloc] initWithData:data];
                                                   NSLog(@"Image retrieved with size: %@", NSStringFromCGSize(self.flickrImage.size));
                                                  //Update the UI pn the main thread
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      
                                                      [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                                      [self.activityIndicator stopAnimating];
                                                      [self.activityIndicator removeFromSuperview];
                                                      
                                                      //Init Image view
                                                      self.imageView = [[UIImageView alloc] initWithImage:self.flickrImage];
                                                      self.imageView.backgroundColor = [UIColor blackColor];
                                                      [self.imageView setUserInteractionEnabled:YES];
                                                      [self.imageView setMultipleTouchEnabled:YES];
                                                      self.imageView.contentMode = UIViewContentModeScaleAspectFit;
                                                      
                                                      //Init Scroll view, set delegate
                                                      self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
                                                      self.scrollView.backgroundColor = [UIColor blackColor];
                                                      self.scrollView.delegate = self;
                                                      self.scrollView.contentSize = self.imageView.bounds.size;
                                                      
                                                      self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                                                      
                                                      //Set up view hierarchy
                                                      [self.scrollView addSubview:self.imageView];
                                                      [self.view addSubview:self.scrollView];
                                                      
                                                      [self calculateZoomScaleAndZoom];
                                                      
                                                      //Enable share button
                                                      [self.shareButton setEnabled:YES];
                                                  });
                                              } else {
                                                  //If we didn't retrieve an image, display a UiLabel message
                                                  NSLog(@"Error retrieving image: %@", error.localizedDescription);
                                                  UILabel *noPhotosLabel = [[UILabel alloc] initWithFrame:CGRectMake(ZERO, ZERO, self.view.bounds.size.width, self.view.bounds.size.height)];
                                                  noPhotosLabel.text = PHOTONOTAVAILABLE;
                                                  noPhotosLabel.textColor = [UIColor lightGrayColor];
                                                  noPhotosLabel.numberOfLines = ZERO;
                                                  noPhotosLabel.textAlignment = NSTextAlignmentCenter;
                                                  noPhotosLabel.font = [UIFont fontWithName:FONTCOPPERPLATE size:12];
                                                  [noPhotosLabel sizeToFit];
                                              }
                                          }];
        [dataTask resume];
    } else {
        self.returnedFromActivityView = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

/*
 When we rotate, update the view hierarchy geometry
 */

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    //Animate the orientation change
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:FASTANIMATION];
    //We need to set the content views size after we rotate
    self.scrollView.contentSize = self.imageView.bounds.size;
    

    //Calculate the mimimum zoom scale (we want to zoom out first to show the entire image)
    [self calculateZoomScaleAndZoom];
    
    self.scrollView.bounds = self.scrollView.frame;
    
    //If the image is square, we need to center the image explicitly
    if (self.flickrImage.size.height == self.flickrImage.size.width) {
        [self centerContentImage];
    }

    [UIView commitAnimations];
}

#pragma mark - Zoom/Scale related methods

- (void)calculateZoomScaleAndZoom {
    
    CGFloat minScale = [self calculateMinScale];
    //Set the 'zoom out' scale to the minimum
    self.scrollView.minimumZoomScale = minScale;
    //Set the 'zoom in' scale to 1 (Max zoom will be image resoultion)
    self.scrollView.maximumZoomScale = MAXZOOM;
    self.scrollView.zoomScale = minScale;
}

- (CGFloat)calculateMinScale {
    
    //Calculate the mimimum zoom scale (we want to zoom out first to show the entire image)
    CGFloat scaleWidth = self.scrollView.frame.size.width / self.scrollView.contentSize.width;
    CGFloat scaleHeight = self.scrollView.frame.size.height / self.scrollView.contentSize.height;
    //The zoom scale will be the minimum of the below zoom scales
    return MIN(scaleWidth, scaleHeight);
}

/*
 We need to center the scrolled image in the view
 */

- (void)centerContentImage {
    
    CGSize scrollViewBounds = self.scrollView.bounds.size;
    CGRect imageviewFrame = self.imageView.frame;
    
    //Width (calculate x)
    if (imageviewFrame.size.width < scrollViewBounds.width) {
        imageviewFrame.origin.x = (scrollViewBounds.width - imageviewFrame.size.width) / 2.0f;
    } else {
        imageviewFrame.origin.x = ZERO;
    }
    
    //Height (calculate y)
    if (imageviewFrame.size.height < scrollViewBounds.height) {
        imageviewFrame.origin.y = (scrollViewBounds.height - imageviewFrame.size.height) / 2.0f;
    } else {
        imageviewFrame.origin.y = ZERO;
    }
    self.imageView.frame = imageviewFrame;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    // The scroll view has zoomed, so you need to re-center the contents
    [self centerContentImage];
}

-(UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

#pragma mark - Share button action

/*NOTE: There are know issues with displaying the MFMailComposeViewController on an iOS8-based simulator
 See http://www.andrewcbancroft.com/2014/08/25/send-email-in-app-using-mfmailcomposeviewcontroller-with-swift/
 "Note that you may have trouble in the iOS 8 Simulator, with symptoms of the composer presenting itself and immediately dismissin"
 Therefore, the following share through mail (and SMS) will only work on a physical device */
- (IBAction)shareFlickrPhoto:(id)sender {
    //Share the photo and the associated title
    NSString *shareText = [NSString stringWithFormat:@"Check out Pete's cool photo! - %@",[self.photoDictionary valueForKey:@"title"]];
    NSArray *items = @[shareText, self.flickrImage];
    UIActivityViewController *activityShareView = [[UIActivityViewController alloc]
                                                   initWithActivityItems:items applicationActivities:nil];
    
    //Exclude all activities except mail & SMS
    activityShareView.excludedActivityTypes = @[UIActivityTypePostToFacebook, UIActivityTypePostToTwitter,UIActivityTypePostToWeibo,UIActivityTypePrint,
                                                UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,
                                                UIActivityTypeAddToReadingList,UIActivityTypePostToFlickr, UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo,
                                                UIActivityTypeAirDrop];
    
    NSString *deviceType = [UIDevice currentDevice].model;
    
    //Deployment device is iPhone, but we may want to support iPad
    //If iPhone display UIActivityIndicator as modal view, else use a popover
    if([deviceType isEqualToString:@"iPhone"]) {
        [self.navigationController presentViewController:activityShareView animated:YES completion:^ {
            self.returnedFromActivityView = YES;
        }];
    } else {
        UIPopoverController* aPopover = [[UIPopoverController alloc]
                                         initWithContentViewController:activityShareView];
        aPopover.delegate = self;
        [aPopover presentPopoverFromBarButtonItem:sender
                         permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

#pragma mark - Gesture recognisers

- (void)imageViewDoubleTapped:(UITapGestureRecognizer *)tapGesture {
    //Only zoom out on double tap is it is zoomed in
    if ([self calculateMinScale] < self.scrollView.zoomScale) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:FASTANIMATION];
        [self calculateZoomScaleAndZoom];
        [UIView commitAnimations];
    }
}

@end
