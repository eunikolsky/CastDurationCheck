//
//  ConnectableDevice+RAC.h
//  CastDurationCheck
//
//  Created by Eugene Nikolskyi on 2015-08-10.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "ConnectableDevice.h"

@class RACSignal;

@interface ConnectableDevice (RAC)

- (RACSignal *)rac_deviceReadySignal;

@end
