//
//  ViewController.m
//  CastDurationCheck
//
//  Created by Eugene Nikolskyi on 2015-08-07.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "ViewController.h"

#import <ConnectSDK.h>

@interface ViewController () <DevicePickerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *labelDuration;

@property (nonatomic, strong) ConnectableDevice *device;
@property (nonatomic, strong) MediaLaunchObject *launchObject;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [[DiscoveryManager sharedManager] startDiscovery];
}

- (IBAction)connect:(id)sender {
    DiscoveryManager *mgr = [DiscoveryManager sharedManager];
    mgr.devicePicker.delegate = self;
    [mgr.devicePicker showPicker:nil];
}
- (IBAction)playVideo0:(id)sender {
    [self playVideoWithURLString:@"http://ec2-54-201-108-205.us-west-2.compute.amazonaws.com/samples/media/video.mp4"];
}
- (IBAction)playVideo1:(id)sender {
    [self playVideoWithURLString:@"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"];
}
- (IBAction)stop:(id)sender {
    [self.launchObject.mediaControl stopWithSuccess:nil failure:nil];
}

- (void)devicePicker:(DevicePicker *)picker
     didSelectDevice:(ConnectableDevice *)device {
    self.device = device;
    [device connect];
}

- (void)playVideoWithURLString:(NSString *)urlString {
    self.launchObject = nil;

    NSURL *mediaURL = [NSURL URLWithString:urlString];
    NSString *title = @"title";
    NSString *description = @"description";
    NSString *mimeType = @"video/mp4";
    BOOL shouldLoop = NO;

    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:mediaURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;

    [self.device.mediaPlayer playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop
                               success:^(MediaLaunchObject *launchObject) {
                                   NSLog(@"display video success");
                                   self.launchObject = launchObject;
                                   [self subscribeToPlayState];
                               } failure:^(NSError *error) {
                                   NSLog(@"display video failure: %@", error.localizedDescription);
                               }];
}

- (void)subscribeToPlayState {
    [self.launchObject.mediaControl subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
        if (MediaControlPlayStatePlaying == playState) {
            [self getDuration];
        }
    }
                                                          failure:nil];
}

- (void)getDuration {
    [self.launchObject.mediaControl getDurationWithSuccess:^(NSTimeInterval duration) {
        NSLog(@">> duration = %f", duration);
        self.labelDuration.text = [NSString stringWithFormat:@"%f sec.", duration];
    }
                                                   failure:^(NSError *error) {
                                                       NSLog(@"!! couldn't get duration %@", error);
                                                   }];
}

@end
