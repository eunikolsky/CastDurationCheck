//
//  DevicePicker+RAC.h
//  CastDurationCheck
//
//  Created by Eugene Nikolskyi on 2015-08-10.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "DevicePicker.h"

@class RACSignal;

@interface DevicePicker (RAC)

- (RACSignal *)rac_selectDeviceSignal;

@end
