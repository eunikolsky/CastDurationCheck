//
//  ViewController.m
//  CastDurationCheck
//
//  Created by Eugene Nikolskyi on 2015-08-07.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "ViewController.h"

#import "ConnectableDevice+RAC.h"
#import "DevicePicker+RAC.h"

#import <ConnectSDK.h>
#import <ReactiveCocoa.h>

static NSString *const VIDEO0_URL = @"http://ec2-54-201-108-205.us-west-2.compute.amazonaws.com/samples/media/video.mp4";
static NSString *const VIDEO1_URL = @"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIButton *playVideo0Button;
@property (weak, nonatomic) IBOutlet UIButton *playVideo1Button;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UILabel *labelDuration;

@property (nonatomic, strong) ConnectableDevice *device;
@property (nonatomic, strong) MediaLaunchObject *launchObject;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    RACSignal *currentDeviceSignal = RACObserve(self, device);

    RACSignal *deviceReadySignal = [[currentDeviceSignal filter:^BOOL(id value) {
        return nil != value;
    }] map:^id(ConnectableDevice *device) {
        return device.rac_deviceReadySignal;
    }];
    RACSignal *buttonsEnabledSignal = [[deviceReadySignal mapReplace:@YES]
        startWith:@NO];

    RACCommand *playVideo0Command = [[RACCommand alloc]
        initWithEnabled:buttonsEnabledSignal
            signalBlock:^RACSignal *(id input) {
                return [RACSignal return:VIDEO0_URL];
            }];
    self.playVideo0Button.rac_command = playVideo0Command;

    RACCommand *playVideo1Command = [[RACCommand alloc]
        initWithEnabled:buttonsEnabledSignal
            signalBlock:^RACSignal *(id input) {
                return [RACSignal return:VIDEO1_URL];
            }];
    self.playVideo1Button.rac_command = playVideo1Command;

    [[[[[RACSignal merge:@[playVideo0Command.executionSignals,
                           playVideo1Command.executionSignals]]
        flatten] map:^(NSString *videoURLString) {
        return [self playVideoWithURLString:videoURLString];
    }] flatten] subscribeNext:^(id x) {
        // this useless subscription is required to kick in playing, because
        // the signal is cold by default
        NSLog(@"play success %@", x);
    }];

    RACCommand *stopVideoCommand = [[RACCommand alloc]
        initWithEnabled:buttonsEnabledSignal
            signalBlock:^RACSignal *(id input) {
                // this signal doesn't require subscription, because it's sent
                // by the command
                return [self stopVideo];
            }];
    self.stopButton.rac_command = stopVideoCommand;

    [stopVideoCommand.executionSignals subscribeNext:^(id x) {
        NSLog(@"stop success %@", x);
    }];

    [currentDeviceSignal subscribeNext:^(ConnectableDevice *device) {
        [device connect];
    }];

    DiscoveryManager *mgr = [DiscoveryManager sharedManager];
    RACSignal *selectDeviceSignal = mgr.devicePicker.rac_selectDeviceSignal;
    RAC(self, device) = selectDeviceSignal;

    RACSignal *connectEnabledSignal = [[selectDeviceSignal mapReplace:@NO]
        startWith:@YES];
    RACCommand *connectCommand = [[RACCommand alloc]
        initWithEnabled:connectEnabledSignal
            signalBlock:^RACSignal *(id input) {
            return [RACSignal empty];
        }];
    [connectCommand.executionSignals subscribeNext:^(id _) {
        [mgr.devicePicker showPicker:nil];
    }];

    self.connectButton.rac_command = connectCommand;

    [[DiscoveryManager sharedManager] startDiscovery];
}

- (RACSignal *)stopVideo {
    NSLog(@"stopping video");

    RACSignal *stopVideoSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.launchObject.mediaControl stopWithSuccess:^(id responseObject) {
                [subscriber sendNext:responseObject];
                [subscriber sendCompleted];
            }
                                                failure:^(NSError *error) {
                                                    [subscriber sendError:error];
                                                }];

        return nil;
    }];

    return stopVideoSignal;
}

- (RACSignal *)playVideoWithURLString:(NSString *)urlString {
    NSLog(@"playing %@", urlString);

    self.launchObject = nil;

    RACSignal *playVideoSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURL *mediaURL = [NSURL URLWithString:urlString];
        MediaInfo *mediaInfo = [self videoInfoWithURL:mediaURL];

        [self.device.mediaPlayer playMediaWithMediaInfo:mediaInfo
                                             shouldLoop:NO
                                                success:^(MediaLaunchObject *launchObject) {
                                                    NSLog(@"display video success");
                                                    self.launchObject = launchObject;
//                                                [self subscribeToPlayState];

                                                    [subscriber sendNext:launchObject];
                                                    [subscriber sendCompleted];
                                                }
                                                failure:^(NSError *error) {
                                                    NSLog(@"display video failure: %@",
                                                          error.localizedDescription);

                                                    [subscriber sendError:error];
                                                }];

        return nil;
    }];

    return playVideoSignal;
}

- (MediaInfo *)videoInfoWithURL:(NSURL *)mediaURL {
    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:mediaURL
                                                 mimeType:@"video/mp4"];
    mediaInfo.title = @"title";
    mediaInfo.description = @"description";
    return mediaInfo;
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
