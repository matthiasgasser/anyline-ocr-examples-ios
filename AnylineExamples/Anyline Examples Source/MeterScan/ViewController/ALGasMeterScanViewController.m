//
//  ViewController.m
//  eScan
//
//  Created by Daniel Albertini on 12/11/14.
//  Copyright (c) 2014 Daniel Albertini. All rights reserved.
//
#import "ALGasMeterScanViewController.h"
#import "ALMeterScanResultViewController.h"
#import <Anyline/Anyline.h>

// This is the license key for the examples project used to set up Aynline below
NSString * const kMeterScanLicenseKey = @"eyJzY29wZSI6WyJBTEwiXSwicGxhdGZvcm0iOlsiaU9TIiwiQW5kcm9pZCIsIldpbmRvd3MiXSwidmFsaWQiOiIyMDE3LTA4LTMwIiwibWFqb3JWZXJzaW9uIjoiMyIsImlzQ29tbWVyY2lhbCI6ZmFsc2UsInRvbGVyYW5jZURheXMiOjYwLCJpb3NJZGVudGlmaWVyIjpbImlvLmFueWxpbmUuZXhhbXBsZXMuYnVuZGxlIl0sImFuZHJvaWRJZGVudGlmaWVyIjpbImlvLmFueWxpbmUuZXhhbXBsZXMuYnVuZGxlIl0sIndpbmRvd3NJZGVudGlmaWVyIjpbImlvLmFueWxpbmUuZXhhbXBsZXMuYnVuZGxlIl19CkIxbU5LZEEvb0JZMlBvRlpsVGV4d3QraHltZTh1S25ON1ZYUStXbE1DY2dYc3RjTnJTL2ZOWVduSHJaSUVORk0vbmNFYWdlVU9Vem9tbmhFNG1tTFY1c3Mxbi8zc2tBQjdjM3pmd25MNkV2Mmx4Y1k4L0htN3Bna2t0K01NanRYODdXMTdWNjBGZWdXTmpXbWF0dmNJSHRFMkhmTEdjUkprQ3BHNFpacm5KWEltVnlkSVJtQmNsamwvWktuZzY1Nm5Rb3ZhMUZzc1p5Q2Vsb3VXSVhpRi9Odk1EcmVraUlaR2JreWVTRk9TT0VxLzgra0xFdHlmZG1yUy8vRjNVZ055YWtXN3NRQXFlNjlUQmN6ak5kVXdQU1lnY3BnSXd0d2puVUJsV2FmdGJ3aW9EKzlNRkowc1JFR2p0OFd5REJ6RHRZSi9EL3NRUm5sSXA2akFjQTNBQT09";

// The controller has to conform to <AnylineEnergyModuleDelegate> to be able to receive results
@interface ALGasMeterScanViewController ()<AnylineEnergyModuleDelegate>

// The Anyline module used to scan
@property (nonatomic, strong) AnylineEnergyModuleView *anylineEnergyView;
// A widget used to choose between meter types
@property (nonatomic, strong) UISegmentedControl *meterTypeSegment;

@property (nonatomic, strong) UILabel *info;

@end

@implementation ALGasMeterScanViewController

/*
 We will do our main setup in viewDidLoad. Its called once the view controller is getting ready to be displayed.
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    // Set the background color to black to have a nicer transition
    self.view.backgroundColor = [UIColor blackColor];
    
    self.title = @"Gas Meter";
    // Initializing the energy module. Its a UIView subclass. We set its frame to fill the whole screen
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    frame = CGRectMake(frame.origin.x, frame.origin.y + self.navigationController.navigationBar.frame.size.height, frame.size.width, frame.size.height - self.navigationController.navigationBar.frame.size.height);
    self.anylineEnergyView = [[AnylineEnergyModuleView alloc] initWithFrame:frame];
    
    NSError *error = nil;
    // We tell the module to bootstrap itself with the license key and delegate. The delegate will later get called
    // once we start receiving results.
    BOOL success = [self.anylineEnergyView setupWithLicenseKey:kMeterScanLicenseKey delegate:self error:&error];
    
    // setupWithLicenseKey:delegate:error returns true if everything went fine. In the case something wrong
    // we have to check the error object for the error message.
    if( !success ) {
        // Something went wrong. The error object contains the error description
        [[[UIAlertView alloc] initWithTitle:@"Setup Error"
                                    message:error.debugDescription
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
    
    
    success = [self.anylineEnergyView setScanMode:ALGasMeter error:&error];

    if( !success ) {
        // Something went wrong. The error object contains the error description
        [[[UIAlertView alloc] initWithTitle:@"ChangeScanMode Error"
                                    message:error.debugDescription
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }

    
    self.anylineEnergyView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // After setup is complete we add the module to the view of this view controller
    [self.view addSubview:self.anylineEnergyView];
    
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[moduleView]|" options:0 metrics:nil views:@{@"moduleView" : self.anylineEnergyView}]];
    
    id topGuide = self.topLayoutGuide;
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide]-0-[moduleView]|" options:0 metrics:nil views:@{@"moduleView" : self.anylineEnergyView, @"topGuide" : topGuide}]];
    
    self.info = [[UILabel alloc] initWithFrame:CGRectMake(0, 160, self.view.frame.size.width, 30)];
    self.info.textColor = [UIColor whiteColor];
    self.info.text = @"5 pre-decimal places";
    self.info.textAlignment = NSTextAlignmentCenter;
    
    [self.anylineEnergyView addSubview:self.info];
    
    // This widget is used to choose between meter types
    self.meterTypeSegment = [[UISegmentedControl alloc] initWithItems:@[@"4 digits",@"5 digits",@"6 digits",@"7 digits"]];
    self.meterTypeSegment.center = CGPointMake(self.view.center.x, self.view.frame.size.height - 40);
    self.meterTypeSegment.selectedSegmentIndex = 1;
    [self.meterTypeSegment addTarget:self action:@selector(segmentChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.meterTypeSegment];
}

- (void)viewDidLayoutSubviews {
    self.info.center = CGPointMake(self.info.center.x, self.anylineEnergyView.cutoutRect.origin.y - 20);
}

/*
 This method will be called once the view controller and its subviews have appeared on screen
 */
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    /*
     This is the place where we tell Anyline to start receiving and displaying images from the camera.
     Success/error tells us if everything went fine.
     */
    NSError *error = nil;
    BOOL success = [self.anylineEnergyView startScanningAndReturnError:&error];
    if( !success ) {
        // Something went wrong. The error object contains the error description
        [[[UIAlertView alloc] initWithTitle:@"Start Scanning Error"
                                    message:error.debugDescription
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

/*
 Cancel scanning to allow the module to clean up
 */
- (void)viewWillDisappear:(BOOL)animated {
    [self.anylineEnergyView cancelScanningAndReturnError:nil];
}

/*
 If the user changes the meter type with the segment control we will tell Anyline it should
 change its scanMode.
 */
- (IBAction)segmentChange:(id)sender {
    BOOL success = YES;
    NSError *error = nil;
    
    switch (self.meterTypeSegment.selectedSegmentIndex) {
        case 0:
            self.info.text = @"4 pre-decimal places";
            success = [self.anylineEnergyView setScanMode:ALAnalogMeter4 error:&error];
            break;
        case 1:
            self.info.text = @"5 pre-decimal places";
            success = [self.anylineEnergyView setScanMode:ALGasMeter error:&error];
            break;
        case 2:
            self.info.text = @"6 pre-decimal places";
            success = [self.anylineEnergyView setScanMode:ALGasMeter6 error:&error];
            break;
        case 3:
        default:
            self.info.text = @"7 pre-decimal places";
            success = [self.anylineEnergyView setScanMode:ALAnalogMeter7 error:&error];
            break;
    }
    
    if( !success ) {
        // Something went wrong. The error object contains the error description
        [[[UIAlertView alloc] initWithTitle:@"ChangeScanMode Error"
                                    message:error.debugDescription
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

#pragma mark - AnylineControllerDelegate methods
/*
 The main delegate method Anyline uses to report its scanned codes
 */
- (void)anylineEnergyModuleView:(AnylineEnergyModuleView *)anylineEnergyModuleView
              didFindScanResult:(NSString *)scanResult
                      cropImage:(UIImage *)image
                      fullImage:(UIImage *)fullImage
                         inMode:(ALScanMode)scanMode {
    ALMeterScanResultViewController *vc = [[ALMeterScanResultViewController alloc] init];
    /*
     To present the scanned result to the user we use a custom view controller.
     */
    vc.scanMode = scanMode;
    vc.meterImage = image;
    vc.result = scanResult;
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end